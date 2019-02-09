pragma solidity 0.4.24;

contract CertificateManager {
    uint    idGenerator; //default is 0
    
    
    // uint: certTypeId
    mapping (uint => CertType) certTypes; 
    struct CertType {
        uint certTypeId;
        string name;
        string issuerName;
        string descUrl;
        address issuerAddress;   // register address
        bool isValid;     // 
        // int grade; // for issuer grade later
    }
    
    // uint personalCertId
    mapping (uint => PersonalCert) personalCerts;
    struct PersonalCert {
        uint certId;
        address ownerAddress;   // student
        uint256 issuedDt;
        uint256 validThroughDt;
        string certNo;    // issued cert. No.
        uint certTypeId;
        bool isConfirmed;  // default false;
    }
   
    // The issuers register certificate
    function registerCertType(string _name, string _issuerName, string _descUrl) public returns(uint){
        //require(msg.value == 1 ether);
        CertType memory newCertType;
        newCertType.certTypeId = idGenerator;
        newCertType.name = _name;
        newCertType.issuerName = _issuerName;
        newCertType.descUrl = _descUrl;
        newCertType.issuerAddress = msg.sender;
        //newCertType.isValid = true;  // need more functionality for validation
       
        certTypes[idGenerator] = newCertType;
        idGenerator++;

        return idGenerator-1;
    }
       
   
   // The student regiester personal certificate
   // TODO: add money
   // TODO: send some money to issuer
   function regiesterPersonalCert(uint256 _issueDt, uint256 _validThroughDt, string _certNo, uint _certTypeId) public returns(uint) {
       require( certTypes[_certTypeId].certTypeId != 0 );
       
       PersonalCert memory newPersonalCert;
       newPersonalCert.certId = idGenerator;
       newPersonalCert.ownerAddress = msg.sender;
       newPersonalCert.issuedDt = _issueDt;
       newPersonalCert.validThroughDt = _validThroughDt;
       newPersonalCert.certNo = _certNo;
       newPersonalCert.certTypeId = _certTypeId;
       newPersonalCert.isConfirmed = false;
       
       personalCerts[idGenerator] = newPersonalCert;
       idGenerator++;

       return idGenerator-1;
   }
   
   
    // The issuer confirm the certificate which was regisered by students
    // Consider: why the issuer pay a gas?
    // because of gas, 
    function confirmCert(uint _certId) public {
        // check proper issuer
        require( personalCerts[_certId].certTypeId != 0 );  // check existence for personalCert
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
    }
    
    
    // generate key value for personal certificate
    function generateCertToken(uint _certId, uint _startDt, uint _endDt) public returns(address){
        // check proper personalCert
        require( personalCerts[_certId].ownerAddress != msg.sender ); // check owner (student)
        
        address tokenAddress = UniqueId.getUniqueId();
        
        CertToken memory newCertToken;
        newCertToken.certId = _certId;
        newCertToken.startDt = _startDt;
        newCertToken.endDt = _endDt;
    
        certTokens[tokenAddress] = newCertToken;
        
        return tokenAddress;
    }
   
    
    modifier checkTokenAddress(address _tokenAddress) {
       require( certTokens[_tokenAddress].tokenAddress == 0);
       require( now >= certTokens[_tokenAddress].startDt && now <= certTokens[_tokenAddress].endDt );
       _;
    }
   
   
    // check token and certNo validation
    // return bool: true=valid, false=not valid
    // return string: reason
    function checkCertToken(address _tokenAddress, string _certNo) checkTokenAddress(_tokenAddress) public view returns(bool) {
        
        if( keccak256(personalCerts[ certTokens[_tokenAddress].certId ].certNo) != keccak256(_certNo) ) {
            return false;
        } else {
            return true;
        }
    }
    
    
    // in: ppcc(publishedPeronsalCertificates)
    // return string: certTypeName
    // return string: issuerName
    // return string: descUrl (for certType)
    
    // return string: certNo
    // return uint256: issuedDate
    // return uint256: validThroughDt
    
    // TODO: add money
    function viewPersonalCert(address _tokenAddress) checkTokenAddress(_tokenAddress) public view returns(string, string, string, string, uint256, uint256) {
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
