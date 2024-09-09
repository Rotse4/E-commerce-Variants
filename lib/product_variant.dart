import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ProductVariantPage extends StatelessWidget {
  final ProductVariantController controller = Get.put(ProductVariantController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Product Variants')),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ElevatedButton(
                      onPressed: controller.addOption,
                      child: Text('Add Option'),
                    ),
                    SizedBox(height: 16),
                    Obx(() => Column(
                      children: controller.options.map((option) => _buildOptionWidget(option)).toList(),
                    )),
                    SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: controller.generateVariants,
                      child: Text('Generate Variants'),
                    ),
                    SizedBox(height: 16),
                    Obx(() => Text('Variants: ${controller.variants.length}')),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: Obx(() => ListView.builder(
              itemCount: controller.variants.length,
              itemBuilder: (context, index) {
                final variant = controller.variants[index];
                return ListTile(
                  title: Text(variant['options'].map((o) => '${o['name']}: ${o['value']}').join(' / ')),
                  subtitle: Text('Total Price: \$${variant['totalPrice'].toStringAsFixed(2)}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Custom Price: '),
                      SizedBox(
                        width: 80,
                        child: TextField(
                          keyboardType: TextInputType.numberWithOptions(decimal: true),
                          onChanged: (value) {
                            controller.setTempCustomPrice(index, double.tryParse(value));
                          },
                          decoration: InputDecoration(
                            hintText: 'Enter price',
                            isDense: true,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.check),
                        onPressed: () => controller.confirmCustomPrice(index),
                      ),
                    ],
                  ),
                );
              },
            )),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionWidget(RxList<dynamic> option) {
    final TextEditingController valueController = TextEditingController();
    final TextEditingController priceController = TextEditingController();

    void addValue() {
      if (valueController.text.isNotEmpty) {
        double? price = double.tryParse(priceController.text);
        // Create a new list with the existing items plus the new one
        List<dynamic> updatedOption = List<dynamic>.from(option);
        updatedOption.add({'value': valueController.text, 'price': price});
        // Update the entire list
        option.value = updatedOption;
        valueController.clear();
        priceController.clear();
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          decoration: InputDecoration(labelText: 'Option Name'),
          onChanged: (value) {
            List<dynamic> updatedOption = List<dynamic>.from(option);
            updatedOption[0] = value;
            option.value = updatedOption;
          },
        ),
        SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: valueController,
                decoration: InputDecoration(hintText: 'Enter value'),
              ),
            ),
            SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: priceController,
                decoration: InputDecoration(hintText: 'Price (optional)'),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
              ),
            ),
            SizedBox(width: 8),
            ElevatedButton(
              onPressed: addValue,
              child: Text('Enter'),
            ),
          ],
        ),
        SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            for (int i = 1; i < option.length; i++)
              Chip(
                label: Text('${option[i]['value']} ${option[i]['price'] != null ? '(\$${option[i]['price']})' : ''}'),
                onDeleted: () => option.removeAt(i),
              ),
          ],
        ),
        SizedBox(height: 16),
      ],
    );
  }
}

class ProductVariantController extends GetxController {
  final options = <RxList<dynamic>>[].obs;
  final variants = <Map<String, dynamic>>[].obs;

  void addOption() {
    options.add(RxList<dynamic>([{'name': ''}]));
  }

  void generateVariants() {
    variants.clear();
    if (options.isNotEmpty) {
      _generateVariantsRecursive([], 0, 0);
    }
  }

  void _generateVariantsRecursive(List<Map<String, dynamic>> current, int optionIndex, double totalPrice) {
    if (optionIndex >= options.length) {
      variants.add({
        'options': current,
        'totalPrice': totalPrice,
        'customPrice': null,
      });
      return;
    }

    final option = options[optionIndex];
    if (option.length > 1) {
      for (int i = 1; i < option.length; i++) {
        List<Map<String, dynamic>> newVariant = List.from(current);
        newVariant.add({
          'name': option[0],
          'value': option[i]['value'],
          'price': option[i]['price'] ?? 0,
        });
        _generateVariantsRecursive(newVariant, optionIndex + 1, totalPrice + (option[i]['price'] ?? 0));
      }
    } else {
      _generateVariantsRecursive(current, optionIndex + 1, totalPrice);
    }
  }

  void setTempCustomPrice(int index, double? price) {
    variants[index]['tempCustomPrice'] = price;
  }

  void confirmCustomPrice(int index) {
    double? tempPrice = variants[index]['tempCustomPrice'];
    if (tempPrice != null) {
      updateVariantPrice(index, tempPrice);
    }
    variants[index]['tempCustomPrice'] = null;
    variants.refresh();
  }

  void updateVariantPrice(int index, double? price) {
    variants[index]['customPrice'] = price;
    if (price != null) {
      variants[index]['totalPrice'] = price;
    } else {
      // Recalculate the total price based on option prices
      double totalPrice = 0;
      for (var option in variants[index]['options']) {
        totalPrice += option['price'] ?? 0;
      }
      variants[index]['totalPrice'] = totalPrice;
    }
    variants.refresh();
  }
}