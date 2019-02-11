pragma solidity 0.4.24;

contract CertManager {

    // key string: certTypeId
    mapping (string => CertType) certTypes;
    struct CertType {
        string certTypeId;
        string name;
        string issuerName;
        string descUrl;
        address issuerAddress;      // register address
        bool isValid;               // if problems is occurred, set it false
    }

    // key string: certId
    mapping (string => PersonalCert) personalCerts;
    struct PersonalCert {
        string certId;
        address ownerAddress;   // student
        string issuedDt;
        string validThroughDt;
        string certNo;    // issued cert. No.
        string certTypeId;
        bool isConfirmed;  // default false;
    }
    
    // key string: tokenId
    mapping (string => CertToken) certTokens;
    struct CertToken {
        string tokenId;
        string certId;
        uint256 startDt;   
        uint256 endDt;  // calculated value: startDt + validDay*60*60*24
        uint validDay;
    }

    address owner;

    modifier onlyOwner() {
        require( owner == msg.sender );
        _;

    }

    constructor() public {
        owner = msg.sender;
    }


    /**
    * The issuers register certificate
    * sample: "0", "Blockchain Proficiency", "Consensys Academy", "https://consensys.net/academy/"
    * sample: "1", "AWS Certification", "AWS", "https://aws.amazon.com/certification/?nc1=h_ls"
    * sample: "2", "TOEIC", "ETS", "https://www.ets.org/toeic"
    */
    function registerCertType(string _certTypeId, string _name, string _issuerName, string _descUrl) public {
        require( bytes(_name).length != 0);
        require( certTypes[_certTypeId].isValid == false); // update is not permitted

        CertType memory newCertType;
        newCertType.certTypeId = _certTypeId;
        newCertType.name = _name;
        newCertType.issuerName = _issuerName;
        newCertType.descUrl = _descUrl;
        newCertType.issuerAddress = msg.sender;
        newCertType.isValid = true;
        
        certTypes[_certTypeId] = newCertType;
    }


    /**
    * The issuer can see his certType info and contract owner can see the all certType info
    * return string: certTypeName
    * return string: issuerName
    * return string: descUrl
    * return bool: isValid
    */
    function viewCertTypeInfo(string _certTypeId) public view returns(string, string, string, bool) {
        require( certTypes[_certTypeId].issuerAddress == msg.sender || owner == msg.sender );

        return (
            certTypes[_certTypeId].name,
            certTypes[_certTypeId].issuerName,
            certTypes[_certTypeId].descUrl,
            certTypes[_certTypeId].isValid
        );
    }


    /** 
    * The student regiester personal certificate
    * sample: "0", "2018-01-01", "2022-01-01", "MyCert123", "0" // Blockchain Proficiency
    * sample: "1", "2018-02-01", "2028-01-01", "MyCertABC", "1" // AWS Certification
    * sample: "2", "2018-03-01", "2099-12-31", "MyCertXYZ", "1" // AWS Certification
    * TODO: add money
    * TODO: send some money to issuer
    */
    function regiesterPersonalCert(string _certId, string _issueDt, string _validThroughDt, string _certNo, string _certTypeId) public  {
        require( bytes(certTypes[_certTypeId].name).length != 0 ); // certType must be generated
        require( bytes(_certNo).length != 0 ); // certNo should not be empty

        PersonalCert memory newPersonalCert;
        newPersonalCert.certId = _certId;
        newPersonalCert.ownerAddress = msg.sender;
        newPersonalCert.issuedDt = _issueDt;
        newPersonalCert.validThroughDt = _validThroughDt;
        newPersonalCert.certNo = _certNo;
        newPersonalCert.certTypeId = _certTypeId;
        newPersonalCert.isConfirmed = false;

        personalCerts[_certId] = newPersonalCert;
    }


    /**
    * The issuer confirm the certificate which was regisered by students
    * Consider: why the issuer pay a gas?
    * because of gas,
    */
    function confirmPersonalCert(string _certId) public {
        require( bytes(personalCerts[_certId].certId).length != 0 );  // check existence for personalCert
        require( personalCerts[_certId].isConfirmed == false );  // for gas ..
        require( certTypes[ personalCerts[_certId].certTypeId ].issuerAddress == msg.sender );  // check certType issuer's address

        // update as confirmed
        personalCerts[_certId].isConfirmed = true;
    }

    function test(string _certId) public view returns(string, uint) {
        if( bytes(personalCerts[_certId].certId).length != 0 )
            
            return ( personalCerts[_certId].certId, 100 );
        else 
            return ( personalCerts[_certId].certId, 999 );
    }

    /**
    * generate key value for personal certificate
    * sample: "0", "0", 10  (valid for 10 days)
    * sample: "1", "0", 0  (for invalid test)
    */
    function registerCertToken(string _tokenId, string _certId, uint _validDay) public {
        // check proper personalCert
        require( personalCerts[_certId].ownerAddress == msg.sender ); // check owner (student)

        CertToken memory newCertToken;
        newCertToken.tokenId = _tokenId;
        newCertToken.certId = _certId;
        newCertToken.startDt = now;
        newCertToken.endDt = now + _validDay*60*60*24;
        newCertToken.validDay = _validDay;

        certTokens[_tokenId] = newCertToken;
    }

    /**
    * check token's existance, duration and confirmeation
    */
    modifier checkTokenAddress(string _tokenId) {
        require( bytes(certTokens[_tokenId].tokenId).length != 0);
        require( now >= certTokens[_tokenId].startDt && now <= certTokens[_tokenId].endDt );
        require( personalCerts[ certTokens[_tokenId].certId ].isConfirmed == true );
        _;
    }


    /**
    * anyone who has a valid token can see the personal cert info
    * return string: certTypeName
    * return string: issuerName
    * return string: descUrl (for certType)
    * return string: certNo
    * return uint256: issuedDate
    * return uint256: validThroughDt
    * TODO: add money
    */
    function viewPersonalCert(string _tokenId) checkTokenAddress(_tokenId) public view returns(string, string, string, string, string, string) {
        string memory certId = certTokens[_tokenId].certId;
        string memory certTypeId = personalCerts[certId].certTypeId;

        return (
            certTypes[certTypeId].name,
            certTypes[certTypeId].issuerName,
            certTypes[certTypeId].descUrl,
            personalCerts[certId].certNo,
            personalCerts[certId].issuedDt,
            personalCerts[certId].validThroughDt
        );
    }


    /**
    * student can see his personal cert info
    * return string: certTypeName
    * return string: issuerName
    * return string: descUrl (for certType)
    * return string: certNo
    * return uint256: issuedDate
    * return uint256: validThroughDt
    * return bool: isConfirmed
    */
    function viewPersonalCertByAdmin(string _certId) public view returns(string, string, string, string, string, string, bool) {
        require( personalCerts[_certId].ownerAddress == msg.sender || owner == msg.sender );

        return (
            certTypes[personalCerts[_certId].certTypeId].name,
            certTypes[personalCerts[_certId].certTypeId].issuerName,
            certTypes[personalCerts[_certId].certTypeId].descUrl,
            personalCerts[_certId].certNo,
            personalCerts[_certId].issuedDt,
            personalCerts[_certId].validThroughDt,
            personalCerts[_certId].isConfirmed
        );
    }


    /**
    * anybody can see the token info because it doesn't include any personal data
    * return address: certId
    * return uint: startDt
    * return uint: endDt (calculated)
    * return uint: durationDay
    * To-be consideration: finding specific student's token is not easy..
    *                      need to change the structure of this code..
    *                      need to manage both all token list and only specific student's tokens ..
    */
    function viewTokenDetail(string _tokenId) public view returns(string, uint, uint, uint) {
        return (
            certTokens[_tokenId].certId,
            certTokens[_tokenId].startDt,
            certTokens[_tokenId].endDt,
            certTokens[_tokenId].validDay
        );
    }


    /**
    * Generate a unique ID that looks like an Ethereum address
    * sample: 0xf4a8f74879182ff2a07468508bec89e1e7464027
    function getUniqueId(int _random) private view returns (address) {
        bytes20 b = bytes20(keccak256(msg.sender, _random, now));
        uint addr = 0;
        for (uint index = b.length-1; index+1 > 0; index--) {
            addr += uint(b[index]) * ( 16 ** ((b.length - index - 1) * 2));
        }

        return address(addr);
    }
    */
}
