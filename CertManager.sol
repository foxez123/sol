pragma solidity ^0.5.0;

contract CertManager {

    
    // key string: certTypeId
    //string[] certTypeIds;
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
    //string[] certIds;
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

    address payable owner = msg.sender;

    modifier onlyOwner() {
        require( owner == msg.sender );
        _;
    }

    /**
    * The issuers register certificate
    * sample: "CT001", "Blockchain Proficiency", "Consensys Academy", "https://consensys.net/academy/"
    * sample: "CT002", "AWS Certification", "AWS", "https://aws.amazon.com/certification/?nc1=h_ls"
    * sample: "CT003", "TOEIC", "ETS", "https://www.ets.org/toeic"
    */
    function registerCertType(string memory _certTypeId, string memory _name, string memory _issuerName, string memory _descUrl) public {
        require( bytes(_name).length != 0, "TEST");
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
    function viewCertTypeInfo(string memory _certTypeId) public view returns(string memory, string memory, string memory, bool) {
        require( certTypes[_certTypeId].issuerAddress == msg.sender || owner == msg.sender );

        return (
            certTypes[_certTypeId].name,
            certTypes[_certTypeId].issuerName,
            certTypes[_certTypeId].descUrl,
            certTypes[_certTypeId].isValid
        );
    }


    uint CERT_REGISTRATION_FEE = 1 ether;
    /** 
    * The student regiester personal certificate
    * sample: "0", "2018-01-01", "2022-01-01", "Blockchain000", "CT001" // Blockchain Proficiency
    * sample: "1", "2018-02-01", "2028-01-01", "AWS_CLOUD_111", "CT002" // AWS Certification
    * sample: "2", "2018-03-01", "2099-12-31", "AWS_CA_2222", "CT002" // AWS Certification
    * TODO: add money
    * TODO: send some money to issuer
    */
    function registerPersonalCert(string memory _certId, string memory _issueDt, string memory _validThroughDt, string memory _certNo, string memory _certTypeId) public payable {
        require( msg.value == CERT_REGISTRATION_FEE );
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
    * examples: 0, 1, 2
    */
    function confirmPersonalCert(string memory _certId) public {
        require( bytes(personalCerts[_certId].certId).length != 0 );  // check existence for personalCert
        require( personalCerts[_certId].isConfirmed == false );  // for gas ..
        require( certTypes[ personalCerts[_certId].certTypeId ].issuerAddress == msg.sender );  // check certType issuer's address

        // update as confirmed
        personalCerts[_certId].isConfirmed = true;
        
        // receive money
        msg.sender.transfer(CERT_REGISTRATION_FEE);
    }


    /**
    * generate key value for personal certificate
    * sample: "0", "0", 10  (valid for 10 days)
    * sample: "1", "0", 0  (for invalid test)
    */
    function registerCertToken(string memory _tokenId, string memory _certId, uint _validDay) public {
        require( personalCerts[_certId].ownerAddress == msg.sender ); // check owner (student)
        require( bytes(certTokens[_tokenId].tokenId).length == 0 );  // only new tokenId is allowed
        
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
    modifier checkTokenAddress(string memory _tokenId) {
        require( bytes(certTokens[_tokenId].tokenId).length != 0);
        require( now >= certTokens[_tokenId].startDt && now <= certTokens[_tokenId].endDt );
        require( personalCerts[ certTokens[_tokenId].certId ].isConfirmed == true , "ERROR");
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
    function viewPersonalCert(string memory _tokenId) checkTokenAddress(_tokenId) public view returns(string memory, string memory, string memory, string memory, string memory, string memory) {
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
    function viewPersonalCertByAdmin(string memory _certId) public view returns(string memory, string memory, string memory, string memory, string memory, string memory, bool) {
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
    function viewTokenDetail(string memory _tokenId) public view returns(string memory, uint, uint, uint) {
        return (
            certTokens[_tokenId].certId,
            certTokens[_tokenId].startDt,
            certTokens[_tokenId].endDt,
            certTokens[_tokenId].validDay
        );
    }
}
