import 'dart:convert'; // for json.decode
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:unosfa/pages/FSAModule/leadsByCampaign.dart';
import 'package:unosfa/widgetSupport/widgetstyle.dart';
import 'package:unosfa/pages/config/config.dart';

class FSACampaignSingleLead extends StatefulWidget {
  final String leadId;
  final String campaign;
  const FSACampaignSingleLead(
      {super.key, required this.leadId, required this.campaign});

  @override
  State<FSACampaignSingleLead> createState() => _FSACampaignSingleLeadState();
}

class _FSACampaignSingleLeadState extends State<FSACampaignSingleLead> {
  final _formKey = GlobalKey<FormState>();
  bool _isEditing = true;
  final idmArnNo = TextEditingController();
  final clientType = TextEditingController();
  final firstName = TextEditingController();
  final lastName = TextEditingController();
  final middleName = TextEditingController();
  final mobilePhone = TextEditingController();
  final birthDate = TextEditingController();
  final gender = TextEditingController();
  final emailAddress = TextEditingController();
  final homePhoneNumber = TextEditingController();
  final branchId = TextEditingController();
  final branchKey = TextEditingController();
  final branch = TextEditingController();
  final ClientIP = TextEditingController();
  final Longitude = TextEditingController();
  final Latitude = TextEditingController();
  final line1 = TextEditingController();
  final line2 = TextEditingController();
  final city = TextEditingController();
  final region = TextEditingController();
  final postcode = TextEditingController();
  final country = TextEditingController();
  final idDocuments = TextEditingController();
  final perm_State = TextEditingController();
  final perm_City = TextEditingController();
  final perm_Street = TextEditingController();
  final perm_Country = TextEditingController();
  final perm_ZipCode = TextEditingController();
  final perm_Barangay = TextEditingController();
  final perm_Region = TextEditingController();
  final perm_countryCode = TextEditingController();
  final hra = TextEditingController();
  final fin_Mthly_Income = TextEditingController();
  final fin_Ownr_Car = TextEditingController();
  final fin_Ann_Income = TextEditingController();
  final fin_Ownr_Home = TextEditingController();
  final fin_Src_Of_Funds = TextEditingController();
  final fin_Src_Of_Funds_Code = TextEditingController();
  final fin_Salary_Period = TextEditingController();
  final fin_Salary_dates = TextEditingController();
  final identity_TinId = TextEditingController();
  final identity_GsisID = TextEditingController();
  final identity_SssID = TextEditingController();
  //Employ Start
  final emp_Work_Nature = TextEditingController();
  final emp_Mths_In_Cur_Comp = TextEditingController();
  final emp_Status = TextEditingController();
  final emp_Employer_Name = TextEditingController();
  final emp_Indus_Type = TextEditingController();
  final emp_Type = TextEditingController();
  final emp_Yrs_In_Cur_Comp = TextEditingController();
  final Office_phone_no = TextEditingController();
  final emp_Type_Code = TextEditingController();
  final emp_Status_Code = TextEditingController();
  final emp_Work_Nature_Code = TextEditingController();
  final emp_Indus_Type_Code = TextEditingController();
  final emp_email = TextEditingController();
  final companyCategorySegment = TextEditingController();
  final profession = TextEditingController();
  final emp_Street = TextEditingController();
  final emp_State = TextEditingController();
  final emp_City = TextEditingController();
  final emp_Country = TextEditingController();
  final emp_ZipCode = TextEditingController();
  final emp_Barangay = TextEditingController();
  final emp_Region = TextEditingController();
  final emp_countryCode = TextEditingController();
  //Employ End
  //Personal_Details Start
  final fatca_Cert_US_Non_US = TextEditingController();
  final fatca_W9_IdNumber = TextEditingController();
  final no_Of_Dependents = TextEditingController();
  final fatca_W9_IdType = TextEditingController();
  final civil_Status = TextEditingController();
  final yrs_In_Residence = TextEditingController();
  final nationality = TextEditingController();
  final marketing_Consent = TextEditingController();
  final mailing_Adrs = TextEditingController();
  final place_Of_Birth = TextEditingController();
  final my_Job = TextEditingController();
  final salutation = TextEditingController();
  final suffix = TextEditingController();
  final nom_Counter = TextEditingController();
  final cust_IdType = TextEditingController();
  final card_Issuance_Status = TextEditingController();
  final my_Job_Code = TextEditingController();
  final vcard_issueDt = TextEditingController();
  final data_Pvcy_Agrmt = TextEditingController();
  final is_Term_Cond_Accepted = TextEditingController();
  final is_Rcds_Edited = TextEditingController();
  final designation = TextEditingController();
  // Spouse_Details
  final spouse_Name = TextEditingController();
  final spouse_Nationality = TextEditingController();
  final spouse_DOB = TextEditingController();
  final spouse_Place_Of_Birth = TextEditingController();
  final spouse_Employment = TextEditingController();
  // Dosri_Check
  final dosriCheck = TextEditingController();
  final dosriName = TextEditingController();
  final dosriRelationship = TextEditingController();
  // rpt_Check
  final rptCheck = TextEditingController();
  final rptName = TextEditingController();
  final rptRelationship = TextEditingController();
  //sourcing customer
  final customerreferralPromoCodeFlag = TextEditingController();
  final customerreferralCode = TextEditingController();
  final customerpromotionalCode = TextEditingController();
  final customersourceCompany = TextEditingController();
  final customeragentCode = TextEditingController();
  //account
  final accountemp_Indus_Type = TextEditingController();
  final accountreferralCode = TextEditingController();
  final accountpromotionalCode = TextEditingController();
  final accountsourceCompany = TextEditingController();
  final accountagentCode = TextEditingController();
  //partner
  final partnerName = TextEditingController();
  final natureOfPartnership = TextEditingController();
  final partnerUserID = TextEditingController();
  final applicationNumber = TextEditingController();
  final expectedMonthlyTransaction = TextEditingController();
  final redirectionURL = TextEditingController();
  //docURL
  final selfieURL = TextEditingController();
  final idProofURL = TextEditingController();
  //partnerScore
  final partnerTelcoScore = TextEditingController();
  final partnerPrefilterScore = TextEditingController();
  final partnerBehaviourScore = TextEditingController();
  final partnerSocialScore = TextEditingController();
  final partnerAdditionalScore1 = TextEditingController();
  final partnerAdditionalScore2 = TextEditingController();
  final partnerAdditionalScore3 = TextEditingController();
  //partnerScreeningStages eKYC
  final emailVerification = TextEditingController();
  final incomeValidation = TextEditingController();
  final addressValidation = TextEditingController();
  final employmentValidation = TextEditingController();
  final referralPromoCodeFlag = TextEditingController();
  final referralCode = TextEditingController();
  final promotionalCode = TextEditingController();
  final sourceCompany = TextEditingController();
  final agentCode = TextEditingController();

  bool _isLoading = true;
  bool isExpanded = false;

  Map<String, dynamic> leadDetails = {}; // To store the lead details

  // Function to fetch lead details by ID
  Future<void> fetchLeadDetails() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('accessToken');
    String? refresh = prefs.getString('refreshToken');
    try {
      final response = await http.get(
        Uri.parse(
            '${AppConfig.baseUrl}/api/campaigns/${widget.campaign}/leads/${widget.leadId}'), // Using leadId in the API URL
        headers: {
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        // Parse the response body as JSON
        setState(() {
          leadDetails = json.decode(response.body);
          firstName.text = leadDetails['first_name'] ?? "";
          lastName.text = leadDetails['last_name'] ?? "";
          middleName.text = leadDetails['middle_name'] ?? "";
          mobilePhone.text = leadDetails['mobile_phone'] ?? "";
          birthDate.text = leadDetails['birth_date'] ?? "";
          gender.text = leadDetails['gender'] ?? "";
          emailAddress.text = "";
          homePhoneNumber.text = "";
          branchId.text = "";
          branchKey.text = "";
          branch.text = "";
          ClientIP.text = "";
          Longitude.text = "";
          Latitude.text = "";
          // Address details
          line1.text =
              leadDetails['perm_street'] + leadDetails['perm_barangay'] ?? "";
          line2.text = leadDetails['perm_state'] ?? "";
          city.text = leadDetails['perm_city'] ?? "";
          region.text = leadDetails['perm_region'] ?? "";
          postcode.text = leadDetails['perm_zip_code'] ?? "";
          country.text = leadDetails['perm_country'] ?? "";
          // Permanent Address
          perm_State.text = leadDetails['perm_state'] ?? "";
          perm_City.text = leadDetails['perm_city'] ?? "";
          perm_Street.text = leadDetails['perm_street'] ?? "";
          perm_Country.text = leadDetails['perm_country'] ?? "";
          perm_ZipCode.text = leadDetails['perm_zip_code'] ?? "";
          perm_Barangay.text = leadDetails['perm_barangay'] ?? "";
          perm_Region.text = leadDetails['perm_region'] ?? "";
          perm_countryCode.text = leadDetails['perm_country_code'] ?? "";
          hra.text = "";

          // Financial Details
          fin_Mthly_Income.text = leadDetails['fin_monthly_income'] ?? "";
          fin_Ann_Income.text = "";
          fin_Src_Of_Funds.text = leadDetails['fin_src_of_funds'] ?? "";
          fin_Src_Of_Funds_Code.text =
              leadDetails['fin_src_of_funds_code'] ?? "";
          fin_Salary_Period.text = "";
          fin_Salary_dates.text = "";

          // Identification Details
          identity_TinId.text = "";
          identity_GsisID.text = "";
          identity_SssID.text = "";
          // Employment Details
          emp_Work_Nature.text = leadDetails['emp_work_nature'] ?? "";
          emp_Mths_In_Cur_Comp.text =
              leadDetails['emp_mths_in_cur_comp'].toString();
          emp_Status.text = leadDetails['emp_status'] ?? "";
          emp_Employer_Name.text = leadDetails['emp_employer_name'] ?? "";
          emp_Indus_Type.text = leadDetails['emp_indus_type'] ?? "";
          emp_Type.text = leadDetails['emp_type'] ?? "";
          emp_Yrs_In_Cur_Comp.text =
              leadDetails['emp_yrs_in_cur_comp']?.toString() ?? "";
          Office_phone_no.text = "";
          emp_email.text = leadDetails['emp_email'] ?? "";

          // Employment Address
          emp_Street.text = leadDetails['emp_street'] ?? "";
          emp_State.text = leadDetails['emp_state'] ?? "";
          emp_City.text = leadDetails['emp_city'] ?? "";
          emp_Country.text = leadDetails['emp_country'] ?? "";
          emp_ZipCode.text = leadDetails['emp_zip_code'] ?? "";
          emp_Barangay.text = leadDetails['emp_barangay'] ?? "";
          emp_Region.text = leadDetails['emp_region'] ?? "";
          emp_countryCode.text = leadDetails['emp_country_code'] ?? "";
          // Personal Details
          fatca_Cert_US_Non_US.text = "";
          no_Of_Dependents.text = "";
          civil_Status.text = leadDetails['civil_status'] ?? "";
          yrs_In_Residence.text = "";
          nationality.text = "";
          marketing_Consent.text = "";
          mailing_Adrs.text = "";
          place_Of_Birth.text = leadDetails['place_of_birth'] ?? "";
          my_Job.text = "";
          salutation.text = "";
          designation.text = "";
          // Spouse Details
          spouse_Name.text = "";
          spouse_Nationality.text = "";
          spouse_DOB.text = "";
          spouse_Place_Of_Birth.text = "";
          spouse_Employment.text = "";
          // Sourcing Customer
          referralPromoCodeFlag.text = "";
          promotionalCode.text = "";
          sourceCompany.text = leadDetails['source_company'] ?? "";
          // Partner Details
          partnerName.text = leadDetails['partner_name'] ?? "";
          natureOfPartnership.text = leadDetails['nature_of_partnership'] ?? "";
          applicationNumber.text = leadDetails['application_number'] ?? "";
          partnerTelcoScore.text = leadDetails['partner_telco_score'] ?? "";
          emailVerification.text = leadDetails['email_verification'] ?? "";
          incomeValidation.text = leadDetails['income_validation'] ?? "";
          addressValidation.text = leadDetails['address_validation'] ?? "";
          employmentValidation.text =
              leadDetails['employment_validation'] ?? "";
          _isLoading = false; // Data loaded
        });
      } else if (response.statusCode == 401) {
        Map<String, dynamic> mappedData = {
          'refresh': refresh,
        };
        final response2 = await http.post(
          Uri.parse(
              '${AppConfig.baseUrl}/api/users/token-refresh/'), // Using leadId in the API URL
          body: mappedData,
        );
        final data = json.decode(response2.body);
        await prefs.setBool('isLoggedIn', true);
        await prefs.setString('accessToken', data['access']);
        await prefs.setString('refreshToken', data['refresh']);
        fetchLeadDetails();
      } else {
        throw Exception('Failed to load lead details');
      }
    } catch (e) {
      print('Error fetching lead details: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    fetchLeadDetails(); // Fetch lead details when the screen is loaded
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(60.0),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFFc433e0),
                Color(0xFF9a37ae),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset('images/logo.PNG', height: 30),
                SizedBox(width: 50),
              ],
            ),
            centerTitle: true,
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => LeadListByCampaign(
                      campaign: widget.campaign,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          Padding(
              padding: const EdgeInsets.all(0.0),
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 20),
                        key: _formKey,
                        child: Form(
                            child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildTextField(
                              firstName,
                              "First Name",
                              'Please Enter First Name',
                              'firstName',
                              isNumeric: false,
                              enabled: _isEditing,
                            ),
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.02,
                            ),
                            _buildTextField(
                              middleName,
                              "Middle Name",
                              'Please Enter Middle Name',
                              'middleName',
                              isNumeric: false,
                              enabled: _isEditing,
                            ),
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.02,
                            ),
                            _buildTextField(
                              lastName,
                              "Last Name",
                              'Please Enter Last Name',
                              'lastName',
                              isNumeric: false,
                              enabled: _isEditing,
                            ),
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.02,
                            ),
                            _buildTextField(
                              mobilePhone,
                              "Mobile Number",
                              'Please Enter Mobile Number',
                              'mobileNumber',
                              isNumeric: true,
                              enabled: _isEditing,
                            ),
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.02,
                            ),
                            _buildTextField(
                              mobilePhone,
                              "Birth Date",
                              'Please Enter Birth Date',
                              'birthDate',
                              enabled: _isEditing,
                            ),
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.02,
                            ),
                            _buildTextField(
                              gender,
                              "Gender",
                              'Please Enter Gender',
                              'gender',
                              enabled: _isEditing,
                            ),
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.02,
                            ),
                            _buildTextField(
                              emailAddress,
                              "Email Address",
                              'Please Enter Email Address',
                              'emailAddress',
                              enabled: _isEditing,
                            ),
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.02,
                            ),
                            _buildTextField(
                              homePhoneNumber,
                              "Home Phone Number",
                              'Please Enter Phone Number',
                              'homePhoneNumber',
                              isPhoneNumber: true,
                              enabled: _isEditing,
                            ),
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.02,
                            ),
                            _buildTextField(
                              branchId,
                              "Branch Id",
                              'Please Enter Branch Id',
                              'branchId',
                              enabled: _isEditing,
                            ),
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.02,
                            ),
                            _buildTextField(
                              branchKey,
                              "Branch Key",
                              'Please Enter Branch Key',
                              'branchKey',
                              enabled: _isEditing,
                            ),
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.02,
                            ),
                            _buildTextField(
                              branch,
                              "Branch",
                              'Please Enter Branch',
                              'branch',
                              enabled: _isEditing,
                            ),
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.02,
                            ),
                            _buildTextField(
                              ClientIP,
                              "Client Ip",
                              'Please Enter Client Ip',
                              'ClientIP',
                              enabled: _isEditing,
                            ),
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.02,
                            ),
                            _buildTextField(
                              line1,
                              "Address Line 1",
                              'Please Enter Address Line 1',
                              'line1',
                              enabled: _isEditing,
                            ),
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.02,
                            ),
                            _buildTextField(
                              line2,
                              "Address Line 2",
                              'Please Enter Address Line 2',
                              'line2',
                              enabled: _isEditing,
                            ),
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.02,
                            ),
                            _buildTextField(
                              city,
                              "City ",
                              'Please Enter City',
                              'city',
                              enabled: _isEditing,
                            ),
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.02,
                            ),
                            _buildTextField(
                              region,
                              "Region ",
                              'Please Enter Region',
                              'region',
                              enabled: _isEditing,
                            ),
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.02,
                            ),
                            _buildTextField(
                              postcode,
                              "Post Code ",
                              'Please Enter Post Code',
                              'postcode',
                              isNumeric: true,
                              enabled: _isEditing,
                            ),
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.02,
                            ),
                            _buildTextField(
                              country,
                              "Country",
                              'Please Enter Cuntry',
                              'country',
                              enabled: _isEditing,
                            ),
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.02,
                            ),
                            _buildTextField(
                              perm_State,
                              "Permenent State",
                              'Please Enter Permenent State',
                              'perm_State',
                              enabled: _isEditing,
                            ),
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.02,
                            ),
                            _buildTextField(
                              perm_City,
                              "Permenent City",
                              'Please Enter Permenent City',
                              'perm_City',
                              enabled: _isEditing,
                            ),
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.02,
                            ),
                            _buildTextField(
                              perm_Street,
                              "Permenent Street",
                              'Please Enter Permenent Street',
                              'perm_Street',
                              enabled: _isEditing,
                            ),
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.02,
                            ),
                            _buildTextField(
                              perm_Country,
                              "Permenent Country",
                              'Please Enter Permenent Country',
                              'perm_Country',
                              enabled: _isEditing,
                            ),
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.02,
                            ),
                            _buildTextField(
                              perm_Barangay,
                              "Permenent Barangay",
                              'Please Enter Permenent Barangay',
                              'perm_Barangay',
                              enabled: _isEditing,
                            ),
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.02,
                            ),
                            _buildTextField(
                              perm_Region,
                              "Permenent Region",
                              'Please Enter Permenent Region',
                              'perm_Region',
                              enabled: _isEditing,
                            ),
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.02,
                            ),
                            _buildTextField(
                              perm_countryCode,
                              "Permenent Country Code",
                              'Please Enter Permenent Country Code',
                              'perm_countryCode',
                              enabled: _isEditing,
                            ),
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.02,
                            ),
                            _buildTextField(
                              fin_Mthly_Income,
                              "Monthly Income",
                              'Please Enter Monthly Income',
                              'fin_Mthly_Income',
                              enabled: _isEditing,
                            ),
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.02,
                            ),
                            _buildTextField(
                              fin_Ownr_Car,
                              "Car Owner",
                              'Please Enter Car Owner',
                              'fin_Ownr_Car',
                              enabled: _isEditing,
                            ),
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.02,
                            ),
                            _buildTextField(
                              fin_Ann_Income,
                              "Annual Income",
                              'Please Enter Annual Income',
                              'fin_Ann_Income',
                              enabled: _isEditing,
                            ),
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.02,
                            ),
                            _buildTextField(
                              fin_Ownr_Home,
                              "Home Owner",
                              'Please Enter Home Owner',
                              'fin_Ownr_Home',
                              enabled: _isEditing,
                            ),
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.02,
                            ),
                            _buildTextField(
                              fin_Src_Of_Funds,
                              "Source Of Fund",
                              'Please Enter Source Of Fund',
                              'fin_Src_Of_Funds',
                              enabled: _isEditing,
                            ),
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.02,
                            ),
                            _buildTextField(
                              fin_Src_Of_Funds_Code,
                              "Source Of Fund Code",
                              'Please Enter Source Of Fund Code',
                              'fin_Src_Of_Funds_Code',
                              enabled: _isEditing,
                            ),
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.02,
                            ),
                            _buildTextField(
                              fin_Salary_Period,
                              "Salary Period",
                              'Please Enter Salary Period',
                              'fin_Salary_Period',
                              enabled: _isEditing,
                            ),
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.02,
                            ),
                            _buildTextField(
                              fin_Salary_dates,
                              "Salary Dates",
                              'Please Enter Salary Dates',
                              'fin_Salary_dates',
                              enabled: _isEditing,
                            ),
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.02,
                            ),
                            _buildTextField(
                              identity_TinId,
                              "Identity Tin Id",
                              'Please Enter Identity Tin Id',
                              'identity_TinId',
                              enabled: _isEditing,
                            ),
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.02,
                            ),
                            _buildTextField(
                              identity_GsisID,
                              "Identity Gsis Id",
                              'Please Enter Identity Gsis Id',
                              'identity_GsisID',
                              enabled: _isEditing,
                            ),
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.02,
                            ),
                            _buildTextField(
                              identity_SssID,
                              "Identity Sss Id",
                              'Please Enter Identity Sss Id',
                              'identity_SssID',
                              enabled: _isEditing,
                            ),
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.02,
                            ),
                            _buildTextField(
                              emp_Work_Nature,
                              "Employ Work Nature",
                              'Please Enter Employ Work Nature',
                              'emp_Work_Nature',
                              enabled: _isEditing,
                            ),
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.02,
                            ),
                            _buildTextField(
                              emp_Mths_In_Cur_Comp,
                              "Employ Months In Current Company",
                              'Please Enter Employ Months In Current Company',
                              'emp_Mths_In_Cur_Comp',
                              enabled: _isEditing,
                            ),
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.02,
                            ),
                            _buildTextField(
                              emp_Status,
                              "Employ Status",
                              'Please Enter Employ Status',
                              'emp_Status',
                              enabled: _isEditing,
                            ),
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.02,
                            ),
                            _buildTextField(
                              emp_Employer_Name,
                              "Employ Employer Name",
                              'Please Enter Employer Name',
                              'emp_Employer_Name',
                              enabled: _isEditing,
                            ),
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.02,
                            ),
                            _buildTextField(
                              emp_Indus_Type,
                              "Employ Industry Type",
                              'Please Enter Industry Type',
                              'emp_Indus_Type',
                              enabled: _isEditing,
                            ),
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.02,
                            ),
                            _buildTextField(
                              emp_Type,
                              "Employ Type",
                              'Please Enter Employ Type',
                              'emp_Type',
                              enabled: _isEditing,
                            ),
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.02,
                            ),
                            _buildTextField(
                              emp_Yrs_In_Cur_Comp,
                              "Employ Years In Current Company",
                              'Please Enter Employ Years In Current Company',
                              'emp_Yrs_In_Cur_Comp',
                              enabled: _isEditing,
                            ),
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.02,
                            ),
                            _buildTextField(
                              Office_phone_no,
                              "Office Phone NUmber",
                              'Please Enter Office Phone Number',
                              'Office_phone_no',
                              enabled: _isEditing,
                            ),
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.02,
                            ),
                            _buildTextField(
                              emp_Type_Code,
                              "Employe Type Code",
                              'Please Enter Employe Type Code',
                              'emp_Type_Code',
                              enabled: _isEditing,
                            ),
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.02,
                            ),
                            _buildTextField(
                              emp_Status_Code,
                              "Employe Status Code",
                              'Please Enter Employe Status Code',
                              'emp_Status_Code',
                              enabled: _isEditing,
                            ),
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.02,
                            ),
                            _buildTextField(
                              emp_Work_Nature_Code,
                              "Employe Work Nature Code",
                              'Please Enter Employe Work Nature Code',
                              'emp_Work_Nature_Code',
                              enabled: _isEditing,
                            ),
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.02,
                            ),
                            _buildTextField(
                              emp_Indus_Type_Code,
                              "Employe Industry Type Code",
                              'Please Enter Employe Industry Type Code',
                              'emp_Indus_Type_Code',
                              enabled: _isEditing,
                            ),
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.02,
                            ),
                            _buildTextField(
                              emp_email,
                              "Employe Email",
                              'Please Enter Employe Email',
                              'emp_email',
                              enabled: _isEditing,
                            ),
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.02,
                            ),
                            _buildTextField(
                              companyCategorySegment,
                              "Company Category Segement",
                              'Please Enter Company Category Segement',
                              'companyCategorySegment',
                              enabled: _isEditing,
                            ),
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.02,
                            ),
                            _buildTextField(
                              profession,
                              "Profession",
                              'Please Enter Profession',
                              'profession',
                              enabled: _isEditing,
                            ),
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.02,
                            ),
                            _buildTextField(
                              emp_Street,
                              "Employe Street",
                              'Please Enter Employe Street',
                              'emp_Street',
                              enabled: _isEditing,
                            ),
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.02,
                            ),
                            _buildTextField(
                              emp_State,
                              "Employe State",
                              'Please Enter Employe State',
                              'emp_State',
                              enabled: _isEditing,
                            ),
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.02,
                            ),
                            _buildTextField(
                              emp_City,
                              "Employe City",
                              'Please Enter Employe City',
                              'emp_City',
                              enabled: _isEditing,
                            ),
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.02,
                            ),
                            _buildTextField(
                              emp_Country,
                              "Employe Country",
                              'Please Enter Employe Country',
                              'emp_Country',
                              enabled: _isEditing,
                            ),
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.02,
                            ),
                            _buildTextField(
                              emp_ZipCode,
                              "Employe Zip Code",
                              'Please Enter Zip Code',
                              'emp_ZipCode',
                              enabled: _isEditing,
                            ),
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.02,
                            ),
                            _buildTextField(
                              emp_Barangay,
                              "Employe Barangay",
                              'Please Enter Barangay',
                              'emp_Barangay',
                              enabled: _isEditing,
                            ),
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.02,
                            ),
                            _buildTextField(
                              emp_Region,
                              "Employe Region",
                              'Please Enter Region',
                              'emp_Region',
                              enabled: _isEditing,
                            ),
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.02,
                            ),
                            _buildTextField(
                              emp_countryCode,
                              "Employe Country Code",
                              'Please Enter Country Code',
                              'emp_countryCode',
                              enabled: _isEditing,
                            ),
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.02,
                            ),
                            _buildTextField(
                              fatca_Cert_US_Non_US,
                              "Fatca Certificate",
                              'Please Enter Fatca Certificate',
                              'fatca_Cert_US_Non_US',
                              enabled: _isEditing,
                            ),
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.02,
                            ),
                            _buildTextField(
                              fatca_W9_IdNumber,
                              "Fatca Id Number",
                              'Please Enter Fatca Id Number',
                              'fatca_W9_IdNumber',
                              enabled: _isEditing,
                            ),
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.02,
                            ),
                            _buildTextField(
                              no_Of_Dependents,
                              "No Of Dependents",
                              'Please Enter No Of Dependents',
                              'no_Of_Dependents',
                              enabled: _isEditing,
                            ),
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.02,
                            ),
                            _buildTextField(
                              fatca_W9_IdType,
                              "Fatca Id Type",
                              'Please Enter Fatca Id Type',
                              'fatca_W9_IdType',
                              enabled: _isEditing,
                            ),
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.02,
                            ),
                            _buildTextField(
                              civil_Status,
                              "Civil Status",
                              'Please Enter Civil Status',
                              'civil_Status',
                              enabled: _isEditing,
                            ),
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.02,
                            ),
                            _buildTextField(
                              yrs_In_Residence,
                              "Years In Residence",
                              'Please Enter Years In Residence',
                              'yrs_In_Residence',
                              enabled: _isEditing,
                            ),
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.02,
                            ),
                            _buildTextField(
                              nationality,
                              "Nationalitye",
                              'Please Enter Nationalitye',
                              'nationality',
                              enabled: _isEditing,
                            ),
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.02,
                            ),
                            _buildTextField(
                              marketing_Consent,
                              "Marketing Consent",
                              'Please Enter Marketing Consent',
                              'marketing_Consent',
                              enabled: _isEditing,
                            ),
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.02,
                            ),
                            _buildTextField(
                              place_Of_Birth,
                              "Place Of Birth",
                              'Please Enter Place Of Birth',
                              'place_Of_Birth',
                              enabled: _isEditing,
                            ),
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.02,
                            ),
                            _buildTextField(
                              my_Job,
                              "Job",
                              'Please Enter Job',
                              'my_Job',
                              enabled: _isEditing,
                            ),
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.02,
                            ),
                            _buildTextField(
                              salutation,
                              "Salutation",
                              'Please Enter Salutation',
                              'salutation',
                              enabled: _isEditing,
                            ),
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.02,
                            ),
                            _buildTextField(
                              suffix,
                              "Suffix",
                              'Please Enter Suffix',
                              'suffix',
                              enabled: _isEditing,
                            ),
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.02,
                            ),
                            _buildTextField(
                              nom_Counter,
                              "Nom Counter",
                              'Please Enter Nom Counter',
                              'nom_Counter',
                              enabled: _isEditing,
                            ),
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.02,
                            ),
                            _buildTextField(
                              cust_IdType,
                              "Customer Id Type",
                              'Please Enter Customer Id Type',
                              'cust_IdType',
                              enabled: _isEditing,
                            ),
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.02,
                            ),
                            _buildTextField(
                              card_Issuance_Status,
                              "Card Issuance Status",
                              'Please Enter Card Issuance Status',
                              'card_Issuance_Status',
                              enabled: _isEditing,
                            ),
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.02,
                            ),
                            _buildTextField(
                              my_Job_Code,
                              "Job Code",
                              'Please Enter Job Code',
                              'my_Job_Code',
                              enabled: _isEditing,
                            ),
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.02,
                            ),
                            _buildTextField(
                              vcard_issueDt,
                              "Visiting Card Issue Date",
                              'Please Enter Visiting Card Issue Date',
                              'vcard_issueDt',
                              enabled: _isEditing,
                            ),
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.02,
                            ),
                            _buildTextField(
                              data_Pvcy_Agrmt,
                              "Data Privacy Agreement",
                              'Please Enter Data Privacy Agreement',
                              'data_Pvcy_Agrmt',
                              enabled: _isEditing,
                            ),
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.02,
                            ),
                            _buildTextField(
                              is_Term_Cond_Accepted,
                              "Terms & Condition Accepted",
                              'Please Enter Terms & Condition Accepted',
                              'is_Term_Cond_Accepted',
                              enabled: _isEditing,
                            ),
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.02,
                            ),
                            _buildTextField(
                              is_Rcds_Edited,
                              "Rcds Edited",
                              'Please Enter Rcds Edited',
                              'is_Rcds_Edited',
                              enabled: _isEditing,
                            ),
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.02,
                            ),
                            _buildTextField(
                              designation,
                              "Designation",
                              'Please Enter Designation',
                              'designation',
                              enabled: _isEditing,
                            ),
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.02,
                            ),
                            _buildTextField(
                              spouse_Name,
                              "Spouse Name",
                              'Please Enter Spouse Name',
                              'spouse_Name',
                              enabled: _isEditing,
                            ),
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.02,
                            ),
                            _buildTextField(
                              spouse_Nationality,
                              "Spouse Nationality",
                              'Please Enter Spouse Nationality',
                              'spouse_Nationality',
                              enabled: _isEditing,
                            ),
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.02,
                            ),
                            _buildTextField(
                              spouse_DOB,
                              "Spouse DOB",
                              'Please Enter Spouse DOB',
                              'spouse_DOB',
                              enabled: _isEditing,
                            ),
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.02,
                            ),
                            _buildTextField(
                              spouse_Place_Of_Birth,
                              "Spouse Place Of Birth",
                              'Please Enter Spouse Place Of Birth',
                              'spouse_Place_Of_Birth',
                              enabled: _isEditing,
                            ),
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.02,
                            ),
                            _buildTextField(
                              spouse_Employment,
                              "Spouse Employment",
                              'Please Enter Spouse Employment',
                              'spouse_Employment',
                              enabled: _isEditing,
                            ),
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.02,
                            ),
                            _buildTextField(
                              dosriCheck,
                              "Dosri Check",
                              'Please Enter Dosri Check',
                              'dosriCheck',
                              enabled: _isEditing,
                            ),
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.02,
                            ),
                            _buildTextField(
                              dosriName,
                              "Dosri Name",
                              'Please Enter Dosri Name',
                              'dosriName',
                              enabled: _isEditing,
                            ),
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.02,
                            ),
                            _buildTextField(
                              dosriRelationship,
                              "Dosri Relationship",
                              'Please Enter Dosri Relationship',
                              'dosriRelationship',
                              enabled: _isEditing,
                            ),
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.02,
                            ),
                            _buildTextField(
                              rptCheck,
                              "RPT Check",
                              'Please Enter RPT Check',
                              'rptCheck',
                              enabled: _isEditing,
                            ),
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.02,
                            ),
                            _buildTextField(
                              rptName,
                              "RPT Name",
                              'Please Enter RPT Name',
                              'rptName',
                              enabled: _isEditing,
                            ),
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.02,
                            ),
                            _buildTextField(
                              rptRelationship,
                              "RPT Relationship",
                              'Please Enter RPT Relationship',
                              'rptRelationship',
                              enabled: _isEditing,
                            ),
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.02,
                            ),
                            _buildTextField(
                              customerreferralCode,
                              "Customer Rreferral PromoCode",
                              'Please Enter Customer Rreferral PromoCode',
                              'customerreferralCode',
                              enabled: _isEditing,
                            ),
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.02,
                            ),
                            _buildTextField(
                              customerreferralCode,
                              "Customer Rreferral Code",
                              'Please Enter Customer Rreferral Code',
                              'customerreferralCode',
                              enabled: _isEditing,
                            ),
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.02,
                            ),
                            _buildTextField(
                              customerpromotionalCode,
                              "Customer Promotional Code",
                              'Please Enter Customer Promotional Code',
                              'customerpromotionalCode',
                              enabled: _isEditing,
                            ),
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.02,
                            ),
                            _buildTextField(
                              customersourceCompany,
                              "Customer Source Company",
                              'Please Enter Customer Source Company',
                              'customersourceCompany',
                              enabled: _isEditing,
                            ),
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.02,
                            ),
                            _buildTextField(
                              customeragentCode,
                              "Customer Agent Code",
                              'Please Enter Customer Agent Cod',
                              'customeragentCode',
                              enabled: _isEditing,
                            ),
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.02,
                            ),
                            _buildTextField(
                              accountpromotionalCode,
                              "Account Promo Code",
                              'Please Enter Customer Promo Code',
                              'accountpromotionalCode',
                              enabled: _isEditing,
                            ),
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.02,
                            ),
                            _buildTextField(
                              accountreferralCode,
                              "Account Referral Code",
                              'Please Enter Account Promo Code',
                              'accountreferralCode',
                              enabled: _isEditing,
                            ),
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.02,
                            ),
                            _buildTextField(
                              accountpromotionalCode,
                              "Account Promo Code",
                              'Please Enter Account Promo Code',
                              'accountpromotionalCode',
                              enabled: _isEditing,
                            ),
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.02,
                            ),
                            _buildTextField(
                              accountsourceCompany,
                              "Account Source Company",
                              'Please Enter Account Source Company',
                              'accountsourceCompany',
                              enabled: _isEditing,
                            ),
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.02,
                            ),
                            _buildTextField(
                              accountagentCode,
                              "Account Agent Code",
                              'Please Enter Account Agent Code',
                              'accountagentCode',
                              enabled: _isEditing,
                            ),
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.02,
                            ),
                            _buildTextField(
                              partnerName,
                              "Partner Name",
                              'Please Enter Partner Name',
                              'partnerName',
                              enabled: _isEditing,
                            ),
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.02,
                            ),
                            _buildTextField(
                              natureOfPartnership,
                              "Nature Of Partnership",
                              'Please Enter Nature Of Partnership',
                              'natureOfPartnership',
                              enabled: _isEditing,
                            ),
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.02,
                            ),
                            _buildTextField(
                              partnerUserID,
                              "Partner User ID",
                              'Please Enter Partner User ID',
                              'partnerUserID',
                              enabled: _isEditing,
                            ),
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.02,
                            ),
                            _buildTextField(
                              applicationNumber,
                              "Application Number",
                              'Please Enter Application Number',
                              'applicationNumber',
                              enabled: _isEditing,
                            ),
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.02,
                            ),
                            _buildTextField(
                              expectedMonthlyTransaction,
                              "Expected Monthly Transaction",
                              'Please Enter Expected Monthly Transaction',
                              'expectedMonthlyTransaction',
                              enabled: _isEditing,
                            ),
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.02,
                            ),
                            _buildTextField(
                              redirectionURL,
                              "Redirection URL",
                              'Please Enter Redirection URL',
                              'redirectionURL',
                              enabled: _isEditing,
                            ),
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.02,
                            ),
                            _buildTextField(
                              selfieURL,
                              "Selfie URL",
                              'Please Enter Selfie URL',
                              'selfieURL',
                              enabled: _isEditing,
                            ),
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.02,
                            ),
                            _buildTextField(
                              idProofURL,
                              "Id Proof URL",
                              'Please Enter Id Proof URL',
                              'idProofURL',
                              enabled: _isEditing,
                            ),
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.02,
                            ),
                            _buildTextField(
                              partnerTelcoScore,
                              "Partner Telco Score",
                              'Please Enter Partner Telco Score',
                              'partnerTelcoScore',
                              enabled: _isEditing,
                            ),
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.02,
                            ),
                            _buildTextField(
                              partnerPrefilterScore,
                              "Partner Prefilter Score",
                              'Please Enter Partner Prefilter Scoree',
                              'partnerPrefilterScore',
                              enabled: _isEditing,
                            ),
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.02,
                            ),
                            _buildTextField(
                              partnerBehaviourScore,
                              "Partner Behaviour Score",
                              'Please Enter Partner Behaviour Score',
                              'partnerBehaviourScore',
                              enabled: _isEditing,
                            ),
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.02,
                            ),
                            _buildTextField(
                              partnerSocialScore,
                              "Partner Social Score",
                              'Please Enter Partner Social Score',
                              'partnerSocialScore',
                              enabled: _isEditing,
                            ),
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.02,
                            ),
                            _buildTextField(
                              partnerAdditionalScore1,
                              "Partner Additional Score 1",
                              'Please Enter Partner Additional Score 1',
                              'partnerAdditionalScore1',
                              enabled: _isEditing,
                            ),
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.02,
                            ),
                            _buildTextField(
                              partnerAdditionalScore2,
                              "Partner Additional Score 2",
                              'Please Enter Partner Additional Score 2',
                              'partnerAdditionalScore2',
                              enabled: _isEditing,
                            ),
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.02,
                            ),
                            _buildTextField(
                              partnerAdditionalScore3,
                              "Partner Additional Score 3",
                              'Please Enter Partner Additional Score 3',
                              'partnerAdditionalScore3',
                              enabled: _isEditing,
                            ),
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.02,
                            ),
                            _buildTextField(
                              emailVerification,
                              "Email Verification",
                              'Please Enter Email Verification',
                              'emailVerification',
                              enabled: _isEditing,
                            ),
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.02,
                            ),
                            _buildTextField(
                              incomeValidation,
                              "Income Verification",
                              'Please Enter Income Verification',
                              'incomeValidation',
                              enabled: _isEditing,
                            ),
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.02,
                            ),
                            _buildTextField(
                              addressValidation,
                              "Address Verification",
                              'Please Enter Address Verification',
                              'addressValidation',
                              enabled: _isEditing,
                            ),
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.02,
                            ),
                            _buildTextField(
                              employmentValidation,
                              "Employment Verification",
                              'Please Enter Employment Verification',
                              'employmentValidation',
                              enabled: _isEditing,
                            ),
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.02,
                            ),
                          ],
                        )),
                      ),
                    )),
          // Floating button positioned at the bottom right corner
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 10), // Adjust padding as needed
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isExpanded) ...[
              Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text("Ineciate Los",
                          style: WidgetSupport.LoginButtonTextColor()),
                      SizedBox(width: 10),
                      FloatingActionButton(
                        heroTag: "btn1",
                        onPressed: () {
                          submitLos();
                          // Navigator.push(
                          //   context,
                          //   MaterialPageRoute(
                          //     builder: (context) => FsaLeadGenerate(edit: ''),
                          //   ),
                          // );
                        },
                        child: Icon(
                          Icons.rocket_launch,
                          color: Colors.white,
                        ),
                        backgroundColor: Colors.blue,
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                ],
              ),
            ],

            // Main Button
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        Colors.blue,
                        Colors.purple
                      ], // Define your gradient colors
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: FloatingActionButton(
                    onPressed: () {
                      setState(() {
                        isExpanded = !isExpanded;
                      });
                    },
                    child: Icon(
                      isExpanded ? Icons.close : Icons.add,
                      color: Colors.white,
                    ),
                    backgroundColor: Colors
                        .transparent, // Set transparent so gradient is visible
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String hintText,
    String validationMessage,
    String validationKey, {
    bool obscureText = false,
    bool isEmail = false,
    bool isPhoneNumber = false,
    bool isNumeric = false,
    bool isZipNumber = false,
    bool enabled = true,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      enabled: enabled,
      keyboardType: isPhoneNumber
          ? TextInputType.phone
          : isEmail
              ? TextInputType.emailAddress
              : isNumeric || isZipNumber
                  ? TextInputType.number
                  : TextInputType.text,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: WidgetSupport.inputLabel(),
      ),
      style: TextStyle(color: Colors.black),
    );
  }

  void submitLos() {
    String CWTransactionID = (Random().nextInt(9) + 1).toString() +
        List.generate(14, (_) => Random().nextInt(10)).join();
    Map<String, dynamic> requestData = {
      "CWTransactionID": CWTransactionID,
      "clientDetails": {
        "ARN": "723561430000",
        "idmArnNo": idmArnNo.text.trim(),
        "clientType": clientType.text.trim(),
        "firstName":
            firstName.text.trim().isNotEmpty ? firstName.text.trim() : null,
        "lastName": lastName.text.trim(),
        "middleName": middleName.text.trim(),
        "mobilePhone": mobilePhone.text.trim(),
        "birthDate": birthDate.text.trim(),
        "gender": gender.text.trim(),
        "emailAddress": emailAddress.text.trim(),
        "homePhoneNumber": homePhoneNumber.text.trim(),
        "branchId": branchId.text.trim(),
        "branchKey": branchKey.text.trim(),
        "branch": branch.text.trim(),
        "ClientIP": ClientIP.text.trim(),
        "Longitude": Longitude.text.trim(),
        "Latitude": Latitude.text.trim(),
        "addresses": [
          {
            "line1": line1.text.trim(),
            "line2": line2.text.trim(),
            "city": city.text.trim(),
            "region": region.text.trim(),
            "postcode": postcode.text.trim(),
            "country": country.text.trim()
          }
        ],
        "idDocuments": null,
        "_Perm_Address": {
          "perm_State": perm_State.text.trim(),
          "perm_City": perm_City.text.trim(),
          "perm_Street": perm_Street.text.trim(),
          "perm_Country": perm_Country.text.trim(),
          "perm_ZipCode": perm_ZipCode.text.trim(),
          "perm_Barangay": perm_Barangay.text.trim(),
          "perm_Region": perm_Region.text.trim(),
          "perm_countryCode": perm_countryCode.text.trim(),
          "hra": hra.text.trim()
        },
        "_Fin_Details": {
          "fin_Mthly_Income": int.tryParse(fin_Mthly_Income.text.trim()) ?? 0,
          "fin_Ownr_Car": "",
          "fin_Ann_Income": fin_Ann_Income.text.trim(),
          "fin_Ownr_Home": "",
          "fin_Src_Of_Funds": fin_Src_Of_Funds.text.trim(),
          "fin_Src_Of_Funds_Code": fin_Src_Of_Funds_Code.text.trim(),
          "fin_Salary_Period": fin_Salary_Period.text.trim(),
          "fin_Salary_dates": fin_Salary_dates.text.trim(),
        },
        "_Identification_Details": {
          "identity_TinId": identity_TinId.text.trim(),
          "identity_GsisID": identity_GsisID.text.trim(),
          "identity_SssID": identity_SssID.text.trim()
        },
        "_Emp_Details": {
          "emp_Work_Nature": emp_Work_Nature.text.trim(),
          "emp_Mths_In_Cur_Comp": emp_Mths_In_Cur_Comp.text.trim(),
          "emp_Status": emp_Status.text.trim(),
          "emp_Employer_Name": emp_Employer_Name.text.trim(),
          "emp_Indus_Type": emp_Indus_Type.text.trim(),
          "emp_Type": emp_Type.text.trim(),
          "emp_Yrs_In_Cur_Comp": emp_Yrs_In_Cur_Comp.text.trim(),
          "Office_phone_no": Office_phone_no.text.trim(),
          "emp_Type_Code": emp_Type_Code.text.trim(),
          "emp_Status_Code": emp_Status_Code.text.trim(),
          "emp_Work_Nature_Code": emp_Work_Nature_Code.text.trim(),
          "emp_Indus_Type_Code": emp_Indus_Type_Code.text.trim(),
          "emp_email": emp_email.text.trim(),
          "companyCategorySegment": companyCategorySegment.text.trim(),
          "profession": profession.text.trim()
        },
        "_Emp_Address": {
          "emp_Street": emp_Street.text.trim(),
          "emp_State": emp_State.text.trim(),
          "emp_City": emp_City.text.trim(),
          "emp_Country": emp_Country.text.trim(),
          "emp_ZipCode": emp_ZipCode.text.trim(),
          "emp_Barangay": emp_Barangay.text.trim(),
          "emp_Region": emp_Region.text.trim(),
          "emp_countryCode": emp_countryCode.text.trim()
        },
        "_Personal_Details": {
          "fatca_Cert_US_Non_US": fatca_Cert_US_Non_US.text.trim(),
          "fatca_W9_IdNumber": fatca_W9_IdNumber.text.trim(),
          "no_Of_Dependents": int.tryParse(no_Of_Dependents.text.trim()) ?? 0,
          "fatca_W9_IdType": fatca_W9_IdType.text.trim(),
          "civil_Status": civil_Status.text.trim(),
          "yrs_In_Residence": yrs_In_Residence.text.trim(),
          "nationality": nationality.text.trim(),
          "marketing_Consent": marketing_Consent.text.trim(),
          "mailing_Adrs": mailing_Adrs.text.trim(),
          "place_Of_Birth": place_Of_Birth.text.trim(),
          "my_Job": my_Job.text.trim(),
          "salutation": salutation.text.trim(),
          "suffix": suffix.text.trim(),
          "nom_Counter": nom_Counter.text.trim(),
          "cust_IdType": cust_IdType.text.trim(),
          "card_Issuance_Status": card_Issuance_Status.text.trim(),
          "my_Job_Code": my_Job_Code.text.trim(),
          "vcard_issueDt": vcard_issueDt.text.trim(),
          "data_Pvcy_Agrmt": data_Pvcy_Agrmt.text.trim(),
          "is_Term_Cond_Accepted": is_Term_Cond_Accepted.text.trim(),
          "is_Rcds_Edited": is_Rcds_Edited.text.trim(),
          "designation": designation.text.trim()
        },
        "_Spouse_Details": {
          "spouse_Name": "Mrs Spouse",
          "spouse_Nationality": "Indian",
          "spouse_DOB": "1960-01-03",
          "spouse_Place_Of_Birth": "india",
          "spouse_Employment": "No"
        },
        "dosri_Check": {
          "dosriCheck": "",
          "dosriName": "",
          "dosriRelationship": ""
        },
        "rpt_Check": {"rptCheck": "", "rptName": "", "rptRelationship": ""}
      },
      "sourcing": {
        "customer": {
          "referralPromoCodeFlag": "Y",
          "referralCode": "",
          "promotionalCode": "TS7",
          "sourceCompany": "TrustingSocial",
          "agentCode": ""
        },
        "account": {
          "referralPromoCodeFlag": "Y",
          "referralCode": "",
          "promotionalCode": "TS7",
          "sourceCompany": "TrustingSocial",
          "agentCode": ""
        }
      },
      "partner": {
        "partnerName": "TrustingSocial",
        "natureOfPartnership": "Lead sourcing",
        "partnerUserID": "",
        "applicationNumber": "7345334567899622",
        "expectedMonthlyTransaction": "",
        "redirectionURL": "N",
        "docURL": {"selfieURL": "", "idProofURL": ""},
        "partnerScore": {
          "partnerTelcoScore": "700",
          "partnerPrefilterScore": "",
          "partnerBehaviourScore": "",
          "partnerSocialScore": "",
          "partnerAdditionalScore1": "",
          "partnerAdditionalScore2": "",
          "partnerAdditionalScore3": ""
        },
        "partnerScreeningStages": {
          "eKYC": {
            "emailVerification": "N",
            "incomeValidation": "N",
            "addressValidation": "N",
            "employmentValidation": "N"
          }
        }
      }
    };

    postLoanCheck(requestData);
  }

  Future<void> postLoanCheck(Map<String, dynamic> requestData) async {
    setState(() {
      _isLoading = true;
    });
    String token = "";
    final tokenUrl =
        Uri.parse('${AppConfig.baseUrl}/api/leads/los-access-token/');
    try {
      final Tokenresponse = await http.get(tokenUrl);
      final data = json.decode(Tokenresponse.body);
      token = data['access_token'];
    } catch (e) {
      print("HTTP Request Failed: $e");
    }
    final url =
        Uri.parse("https://unoapi.uat.ph.unobank.asia/partner/loans/check");

    final headers = {
      "Idempotency-Key": "th37per9-185d-4e22-83fb-18gf96g0g861",
      "Content-Type": "application/json",
      "Accept": "application/json",
      "Authorization": "Bearer $token",
    };

    try {
      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(requestData),
      );

      if (response.statusCode == 201) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text("Success"),
              content: Text("LOS Initiated Successfully"),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => LeadListByCampaign(
                          campaign: widget.campaign,
                        ),
                      ),
                    );
                  },
                  child: Text("OK"),
                ),
              ],
            );
          },
        );
      } else if (response.statusCode == 400) {
        final data = json.decode(response.body);

        // Extracting the message
        String message = data['message'] ?? "Validation Error";

        // Extracting and formatting the errors
        Map<String, dynamic> errors = data['errors'] ?? {};
        String errorMessages = errors.entries
            .map((entry) => "${entry.value}")
            .join("\n"); // Joins all errors with a new line

        // Show the AlertDialog
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text("Error"),
              content: Text("$message\n\n$errorMessages"),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text("OK"),
                ),
              ],
            );
          },
        );
      }
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print("HTTP Request Failed: $e");

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("Error"),
            content: Text("An error occurred. Please try again."),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text("OK"),
              ),
            ],
          );
        },
      );

      setState(() {
        _isLoading = false;
      });
    }
  }
}
