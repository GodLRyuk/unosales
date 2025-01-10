import 'package:flutter/material.dart';
import 'package:unosfa/pages/generalscreens/custommenudrawer.dart';
import 'package:unosfa/widgetSupport/widgetstyle.dart';

class Calculator extends StatefulWidget {
  @override
  State<Calculator> createState() => _CalculatorState();
}

class _CalculatorState extends State<Calculator> {
  double _loanAmount = 200000;

  double _loanTimePeriod = 3;

  double _loanRateIntrest = 6.5;

  int _selectedDay = 1;

  int _selectedMonth = 1;

  int _selectedYear = DateTime.now().year;

  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      title: 'Calculator', // Title for the AppBar
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 15.0),
          child: Column(
            children: [
              Stack(
                children: [
                  Container(
                    width: MediaQuery.of(context).size.width,
                    padding: const EdgeInsets.all(0.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Emi Calculator",
                          style: WidgetSupport.titleText(),
                        ),
                        SizedBox(height: 5),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Title on the left
                            Padding(
                              padding: const EdgeInsets.only(
                                  top: 0, bottom: 0, left: 20),
                              child: Text(
                                "Select Loan Amount",
                                style: WidgetSupport.textBlack20(),
                              ),
                            ),
                            // Loan amount text on the right
                            Padding(
                              padding: const EdgeInsets.all(20.0),
                              child: Container(
                                width: 70,
                                color: Color(0xFFa604ad),
                                child: Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(2.0),
                                    child: Text(
                                      " \u20B1${_loanAmount.toStringAsFixed(0)}",
                                      style: WidgetSupport.textWhite20(),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        // Slider positioned below the title and loan amount
                        Row(
                          children: [
                            Expanded(
                              child: Slider(
                                value: _loanAmount,
                                min: 1000, // Minimum loan amount
                                max: 500000, // Maximum loan amount
                                divisions:
                                    50, // Number of divisions for finer control
                                label: _loanAmount.toStringAsFixed(0),
                                onChanged: (double value) {
                                  setState(() {
                                    _loanAmount = value; // Update the loan amount
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Stack(
                children: [
                  Container(
                    width: MediaQuery.of(context).size.width,
                    padding: const EdgeInsets.all(0.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Row for Title and Loan Amount
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Title on the left
                            Padding(
                              padding: const EdgeInsets.only(
                                  top: 0, bottom: 0, left: 20),
                              child: Text(
                                "Rate of intrest(p.a)",
                                style: WidgetSupport.textBlack20(),
                              ),
                            ),
                            // Loan amount text on the right
                            Padding(
                              padding: const EdgeInsets.all(20.0),
                              child: Container(
                                width: 70,
                                color: Color(0xFFa604ad),
                                child: Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(2.0),
                                    child: Text(
                                      "${_loanRateIntrest.toStringAsFixed(0)} %",
                                      style: WidgetSupport.textWhite20(),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        // Slider positioned below the title and loan amount
                        Row(
                          children: [
                            Expanded(
                              child: Slider(
                                value: _loanRateIntrest,
                                min: 1, // Minimum loan amount
                                max: 30, // Maximum loan amount
                                divisions:
                                    50, // Number of divisions for finer control
                                label: _loanRateIntrest.toStringAsFixed(0),
                                onChanged: (double value) {
                                  setState(() {
                                    _loanRateIntrest =
                                        value; // Update the loan amount
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Stack(
                children: [
                  Container(
                    width: MediaQuery.of(context).size.width,
                    padding: const EdgeInsets.all(0.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Row for Title and Loan Amount
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Title on the left
                            Padding(
                              padding: const EdgeInsets.all(20.0),
                              child: Text(
                                "Loan Time Period",
                                style: WidgetSupport.textBlack20(),
                              ),
                            ),
                            // Loan amount text on the right
                            Padding(
                              padding: const EdgeInsets.all(20.0),
                              child: Container(
                                width: 70,
                                color: Color(0xFFa604ad),
                                child: Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(2.0),
                                    child: Text(
                                      "${_loanTimePeriod.toStringAsFixed(0)} Yr",
                                      style: WidgetSupport.textWhite20(),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        // Slider positioned below the title and loan amount
                        Row(
                          children: [
                            Expanded(
                              child: Slider(
                                value: _loanTimePeriod,
                                min: 1, // Minimum loan amount
                                max: 30, // Maximum loan amount
                                divisions:
                                    50, // Number of divisions for finer control
                                label: _loanTimePeriod.toStringAsFixed(0),
                                onChanged: (double value) {
                                  setState(() {
                                    _loanTimePeriod =
                                        value; // Update the loan amount
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Stack(
                children: [
                  Container(
                    width: MediaQuery.of(context).size.width,
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            "Select Payment Day",
                            style: WidgetSupport.textBlack20(),
                          ),
                        ),
                        SizedBox(height: 10),
        
                        // Select Day
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: DropdownButtonFormField<int>(
                            value: _selectedDay,
                            decoration: InputDecoration(
                              labelText: 'Select Day',
                            ),
                            items: List.generate(31, (index) {
                              return DropdownMenuItem<int>(
                                value: index + 1,
                                child: Text((index + 1).toString()),
                              );
                            }),
                            onChanged: (int? value) {
                              setState(() {
                                _selectedDay =
                                    value ?? 1; // Update the selected day
                              });
                            },
                          ),
                        ),
                        SizedBox(height: 10),
                        // Select Month
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: DropdownButtonFormField<int>(
                            value: _selectedMonth,
                            decoration: InputDecoration(
                              labelText: 'Select Month',
                            ),
                            items: List.generate(12, (index) {
                              return DropdownMenuItem<int>(
                                value: index + 1,
                                child: Text([
                                  'Jan',
                                  'Feb',
                                  'Mar',
                                  'Apr',
                                  'May',
                                  'Jun',
                                  'Jul',
                                  'Aug',
                                  'Sep',
                                  'Oct',
                                  'Nov',
                                  'Dec'
                                ][index]),
                              );
                            }),
                            onChanged: (int? value) {
                              setState(() {
                                _selectedMonth =
                                    value ?? 1; // Update the selected month
                              });
                            },
                          ),
                        ),
                        SizedBox(height: 10),
        
                        // Select Year
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: DropdownButtonFormField<int>(
                            value: _selectedYear,
                            decoration: InputDecoration(
                              labelText: 'Select Year',
                            ),
                            items: List.generate(30, (index) {
                              int year = DateTime.now().year + index;
                              return DropdownMenuItem<int>(
                                value: year,
                                child: Text(year.toString()),
                              );
                            }),
                            onChanged: (int? value) {
                              setState(() {
                                _selectedYear = value ??
                                    DateTime.now()
                                        .year; // Update the selected year
                              });
                            },
                          ),
                        ),
                        // SizedBox(height: 20),
        
                        // // Display the selected date
                        // Text(
                        //   "Selected Date: ${_selectedDay}/${_selectedMonth}/${_selectedYear}",
                        //   style: WidgetSupport.textBlack20(),
                        // ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
