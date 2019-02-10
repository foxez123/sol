/**
 * 초기 버전으로 javascript VM에서는 작동이 잘 됐으나 web3에서 문제가 발생했음.
 * 문제점은 블록체인 데이터 업데이트 시 web3에서는 리턴값을 받아 올 수 없음.
 */
pragma solidity 0.4.24;

contract CertificateManager {
    uint    certTypeIdGenerator = 1; //default is 1
    uint    certIdGenerator = 1; //default is 1
    
    // uint: certTypeId
    mapping (uint => CertType) certTypes; 
    struct CertType {
        uint certTypeId;
        string name;
        string issuerName;
        string descUrl;
        address issuerAddress;      // register address
        bool isValid;               // if problems is occurred, invalid the specific certType
    }
    
    // uint: certId
    mapping (uint => PersonalCert) personalCerts;
    struct PersonalCert {
        uint certId;
        address ownerAddress;   // student
        string issuedDt;    
        string validThroughDt;
        string certNo;    // issued cert. No.
        uint certTypeId;
        bool isConfirmed;  // default false;
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
    * sample: "TOEIC", "ETS", "https://www.ets.org/toeic"
    * sample: "AWS Certification", "AWS", "https://aws.amazon.com/certification/?nc1=h_ls"
    * sample: "Blockchain Proficiency", Consensys Academy", "https://consensys.net/academy/"
    */ 
    function registerCertType(string _name, string _issuerName, string _descUrl) public returns(uint){
        require( bytes(_name).length != 0);
        
        CertType memory newCertType;
        newCertType.certTypeId = certTypeIdGenerator;
        newCertType.name = _name;
        newCertType.issuerName = _issuerName;
        newCertType.descUrl = _descUrl;
        newCertType.issuerAddress = msg.sender;
        //newCertType.isValid = true;  // need more functionality for validation
       
        certTypes[certTypeIdGenerator] = newCertType;
        certTypeIdGenerator++;

        return certTypeIdGenerator-1;
    }
    

    /**
    * The issuer can see his certType info and contract owner can see the all certType info
    * return string: certTypeName
    * return string: issuerName
    * return string: descUrl
    */
    function viewCertTypeInfo(uint _certTypeId) public view returns(string, string, string) {
        require( certTypes[_certTypeId].issuerAddress == msg.sender || owner == msg.sender );
        
        return (
            certTypes[_certTypeId].name,
            certTypes[_certTypeId].issuerName,
            certTypes[_certTypeId].descUrl
            );
    }


    /** The student regiester personal certificate
    * TODO: add money
    * TODO: send some money to issuer
    * sample data: "2018-01-01", "2022-01-01", "MyCert1", 1
    * sample data: "2018-02-01", "2099-12-31", "MyCert2", 2
    */
    function regiesterPersonalCert(string _issueDt, string _validThroughDt, string _certNo, uint _certTypeId) public returns(uint) {
        require( bytes(certTypes[_certTypeId].name).length != 0 ); // certType must be generated
        require( bytes(_certNo).length != 0 ); // certNo should not be empty
       
        PersonalCert memory newPersonalCert;
        newPersonalCert.certId = certIdGenerator;
        newPersonalCert.ownerAddress = msg.sender;
        newPersonalCert.issuedDt = _issueDt;
        newPersonalCert.validThroughDt = _validThroughDt;
        newPersonalCert.certNo = _certNo;
        newPersonalCert.certTypeId = _certTypeId;
        newPersonalCert.isConfirmed = false;
       
        personalCerts[certIdGenerator] = newPersonalCert;
        certIdGenerator++;

        return certIdGenerator-1;
    }
   
   
    /**
    * The issuer confirm the certificate which was regisered by students
    * Consider: why the issuer pay a gas?
    * because of gas, 
    */
    function confirmCert(uint _certId) public {
        require( personalCerts[_certId].certTypeId != 0 );  // check existence for personalCert
        require( personalCerts[_certId].isConfirmed == false );  // for gas ..
        require( certTypes[ personalCerts[_certId].certTypeId ].issuerAddress == msg.sender );  // check certType issuer's address
        
        // update as confirmed
        personalCerts[_certId].isConfirmed = true;
    }
    
    
    mapping (address => CertToken) certTokens;
    struct CertToken {
        address tokenAddress;
        uint certId;
        uint256 startDt;
        uint256 endDt;
        uint validDay;
    }
    
    
    /**
    * generate key value for personal certificate
    * sample: 1, 10  (valid for 10 days)
    * sample: 1, 0  (for invalid test)
    */
    function generateCertToken(uint _certId, uint _validDay) public returns(address){
        // check proper personalCert
        require( personalCerts[_certId].ownerAddress == msg.sender ); // check owner (student)
        
        address tokenAddress = UniqueId.getUniqueId();
        
        CertToken memory newCertToken;
        newCertToken.certId = _certId;
        newCertToken.startDt = now;
        newCertToken.endDt = now + _validDay*60*60*24;
        newCertToken.validDay = _validDay;
    
        certTokens[tokenAddress] = newCertToken;
        
        return tokenAddress;
    }
   
    
    
    modifier checkTokenAddress(address _tokenAddress) {
       require( certTokens[_tokenAddress].tokenAddress == 0);
       require( now >= certTokens[_tokenAddress].startDt && now <= certTokens[_tokenAddress].endDt );
       require( personalCerts[ certTokens[_tokenAddress].certId ].isConfirmed == true );
       _;
    }
   
   
    // check token and certNo validation
    // return bool: true=valid, false=not valid
    // return string: reason
    /*
    function checkCertToken(address _tokenAddress, string _certNo) checkTokenAddress(_tokenAddress) public view returns(bool) {
        
        if( keccak256(personalCerts[ certTokens[_tokenAddress].certId ].certNo) != keccak256(_certNo) ) {
            return false;
        } else {
            return true;
        }
    }
    */
    
    
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
    function viewPersonalCert(address _tokenAddress) checkTokenAddress(_tokenAddress) public view returns(string, string, string, string, string, string) {
        uint certId = certTokens[_tokenAddress].certId;
        uint certTypeId = personalCerts[certId].certTypeId;
        
        return (
            certTypes[certTypeId].name,
            certTypes[certTypeId].issuerName,
            certTypes[certTypeId].descUrl,
            personalCerts[certId].certNo, 
            personalCerts[certId].issuedDt,
            personalCerts[certId].validThroughDt);
               
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
    function viewPersonalCert(uint _certId) public view returns(string, string, string, string, string, string, bool) {
        require( personalCerts[_certId].ownerAddress == msg.sender || owner == msg.sender );
        
        return (
            certTypes[personalCerts[_certId].certTypeId].name,
            certTypes[personalCerts[_certId].certTypeId].issuerName,
            certTypes[personalCerts[_certId].certTypeId].descUrl,
            personalCerts[_certId].certNo, 
            personalCerts[_certId].issuedDt,
            personalCerts[_certId].validThroughDt,
            personalCerts[_certId].isConfirmed);
               
    }
    
    
    /**
    * anybody can see the token info because it doesn't include any personal data
    * return uint: certId
    * return uint: startDt
    * return uint: durationDay 
    * To-be consideration: finding specific student's token is not easy.. 
    *                      need to change the structure of this code.. 
    *                      need to manage both all token list and only specific student's tokens ..
    */
    function viewTokenDetail(address _tokenAddress) public view returns(uint, uint, uint) {
        return (
            certTokens[_tokenAddress].certId,
            certTokens[_tokenAddress].startDt,
            certTokens[_tokenAddress].validDay
            );
    }
}



library UniqueId {

    /**
    * @dev Generate a unique ID that looks like an Ethereum address
    *
    * Sample: 0xf4a8f74879182ff2a07468508bec89e1e7464027		          
    */  
    function getUniqueId() public view returns (address) 
    {

        bytes20 b = bytes20(keccak256(msg.sender, now));
        uint addr = 0;
        for (uint index = b.length-1; index+1 > 0; index--) {
            addr += uint(b[index]) * ( 16 ** ((b.length - index - 1) * 2));
        }

        return address(addr);
    }
}
