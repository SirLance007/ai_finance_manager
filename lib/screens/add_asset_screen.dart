import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ai_finance_manager/theme/app_colors.dart';
import 'package:ai_finance_manager/services/finance_api_service.dart';

class AddAssetScreen extends StatefulWidget {
  const AddAssetScreen({super.key});

  @override
  State<AddAssetScreen> createState() => _AddAssetScreenState();
}

class _AddAssetScreenState extends State<AddAssetScreen> {
  final _tickerController = TextEditingController();
  final _quantityController = TextEditingController();
  final _buyPriceController = TextEditingController();
  
  bool _isLoading = false;
  String _validationMsg = "";
  Color _validationColor = Colors.grey;

  Future<void> _verifyAndSave() async {
    final ticker = _tickerController.text.trim().toUpperCase();
    final qtyStr = _quantityController.text.trim();
    final priceStr = _buyPriceController.text.trim();
    
    if (ticker.isEmpty || qtyStr.isEmpty || priceStr.isEmpty) {
      setState(() {
        _validationMsg = "All fields are required.";
        _validationColor = Colors.red;
      });
      return;
    }

    final double? qty = double.tryParse(qtyStr);
    final double? buyPrice = double.tryParse(priceStr);

    if (qty == null || buyPrice == null) {
      setState(() {
        _validationMsg = "Quantity and Price must be valid numbers.";
        _validationColor = Colors.red;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _validationMsg = "Verifying live API...";
      _validationColor = Colors.orange;
    });

    final isValid = await FinanceApiService.verifyTicker(ticker);
    
    if (!isValid) {
      setState(() {
        _isLoading = false;
        _validationMsg = "Invalid Ticker symbol. Make sure you use standard Yahoo finance symbols (e.g. RELIANCE.NS, BTC-USD)";
        _validationColor = Colors.red;
      });
      return;
    }

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('portfolio')
            .add({
          'ticker': ticker,
          'quantity': qty,
          'buyPrice': buyPrice,
          'dateAdded': FieldValue.serverTimestamp(),
        });
        
        if (mounted) {
          Navigator.pop(context);
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _validationMsg = "Failed to save: $e";
        _validationColor = Colors.red;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Add New Holding", style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: AppColors.textDark),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Add your real stocks or crypto to track them live via market APIs.",
              style: TextStyle(color: AppColors.textLight, fontSize: 14),
            ),
            const SizedBox(height: 32),
            _buildSearchField(),
            const SizedBox(height: 20),
            
            Row(
              children: [
                Expanded(child: _buildTextField("Quantity", _quantityController, isNumber: true, hint: "e.g., 10")),
                const SizedBox(width: 16),
                Expanded(child: _buildTextField("Buy Price", _buyPriceController, isNumber: true, hint: "e.g., ₹2500")),
              ],
            ),
            
            const SizedBox(height: 12),
            if (_validationMsg.isNotEmpty) 
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  children: [
                    Icon(LucideIcons.info, color: _validationColor, size: 16),
                    const SizedBox(width: 8),
                    Expanded(child: Text(_validationMsg, style: TextStyle(color: _validationColor, fontSize: 12))),
                  ],
                ),
              ),
              
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _verifyAndSave,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: _isLoading 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text("Save Asset & Sync API", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {bool isNumber = false, String? hint}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textDark)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: isNumber ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
          textCapitalization: isNumber ? TextCapitalization.none : TextCapitalization.characters,
          style: const TextStyle(fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.normal),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Search Ticker or Company", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textDark)),
        const SizedBox(height: 8),
        Autocomplete<Map<String, dynamic>>(
          optionsBuilder: (TextEditingValue textEditingValue) async {
            _tickerController.text = textEditingValue.text;
            if (textEditingValue.text.isEmpty) return const Iterable<Map<String, dynamic>>.empty();
            return await FinanceApiService.searchTickers(textEditingValue.text);
          },
          displayStringForOption: (option) => option['symbol']?.toString() ?? '',
          onSelected: (option) {
            _tickerController.text = option['symbol']?.toString() ?? '';
            FocusManager.instance.primaryFocus?.unfocus();
          },
          fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
            return TextField(
              controller: controller,
              focusNode: focusNode,
              textCapitalization: TextCapitalization.characters,
              style: const TextStyle(fontWeight: FontWeight.w500),
              decoration: InputDecoration(
                hintText: "e.g., Zomato, Reliance, TSLA",
                hintStyle: const TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.normal),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                prefixIcon: const Icon(LucideIcons.search, size: 18, color: Colors.grey),
              ),
            );
          },
          optionsViewBuilder: (context, onSelected, options) {
            return Align(
              alignment: Alignment.topLeft,
              child: Material(
                elevation: 4.0,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: MediaQuery.of(context).size.width - 48,
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shrinkWrap: true,
                    itemCount: options.length,
                    itemBuilder: (context, index) {
                      final option = options.elementAt(index);
                      return ListTile(
                        title: Text(option['shortname']?.toString() ?? option['symbol'].toString(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        subtitle: Text("${option['symbol']} • ${option['exchDisp']}", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                        onTap: () => onSelected(option),
                      );
                    },
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
