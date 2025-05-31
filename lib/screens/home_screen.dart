import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/dog_api_service.dart'; // sesuaikan path sesuai struktur proyekmu
import '../models/dog_breed_model.dart';
import 'dog_breed_detail_screen.dart'; // halaman detail dog breed

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with AutomaticKeepAliveClientMixin {
  String search = "";
  List<String> listWaktuBagian = <String>['WIB', 'WITA', 'WIT', 'UTC'];
  late String waktuBagian = 'WIB';
  late String timeString;
  late Timer timer;

  // ✅ PERBAIKAN 1: Buat Future sekali saja, tidak di build()
  late Future<List<DogBreed>> _breedsFuture;
  String _lastSearch = "";

  @override
  bool get wantKeepAlive => true; // ✅ PERBAIKAN 2: Jaga state tetap hidup

  @override
  void initState() {
    super.initState();
    timeString = _formatDateTime(DateTime.now());
    timer = Timer.periodic(const Duration(seconds: 1), (Timer t) => _getTime());

    // ✅ PERBAIKAN 3: Inisialisasi Future di initState
    _breedsFuture = DogApiService.fetchAllBreeds();
  }

  @override
  void dispose() {
    timer.cancel();
    super.dispose();
  }

  void _getTime() {
    DateTime waktu;
    if (waktuBagian == 'WITA') {
      waktu = DateTime.now().add(const Duration(hours: 1));
    } else if (waktuBagian == 'WIT') {
      waktu = DateTime.now().add(const Duration(hours: 2));
    } else if (waktuBagian == 'UTC') {
      waktu = DateTime.now().toUtc();
    } else {
      waktu = DateTime.now();
    }

    // ✅ PERBAIKAN 4: Hanya update waktu, tidak rebuild seluruh widget
    if (mounted) {
      setState(() {
        timeString = _formatDateTime(waktu);
      });
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return DateFormat('kk:mm:ss').format(dateTime);
  }

  Widget searchField() {
    return Container(
      width: double.infinity,
      height: 50,
      child: TextFormField(
        onFieldSubmitted: (value) {
          final trimmedValue = value.trim();
          if (trimmedValue != _lastSearch) {
            setState(() {
              search = trimmedValue;
              _lastSearch = trimmedValue;
              // ✅ PERBAIKAN 5: Update Future hanya saat search berubah
              _breedsFuture = search.isEmpty
                  ? DogApiService.fetchAllBreeds()
                  : DogApiService.searchBreeds(search);
            });
          }
        },
        style: const TextStyle(fontSize: 14),
        cursorColor: const Color(0xffAD8B73),
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.search_outlined),
          hintText: 'Search for dog breeds',
          border: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(30)),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // ✅ Wajib untuk AutomaticKeepAliveClientMixin

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dogs Breeds'),
        backgroundColor: const Color(0xffCEAB93),
      ),
      body: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Waktu dan Dropdown zona waktu
            Container(
              width: MediaQuery.of(context).size.width / 1.6,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: const Color(0xffF5EBEB),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    child: Text(
                      timeString,
                      style: const TextStyle(
                        fontSize: 25,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: DropdownButton<String>(
                      underline: Container(),
                      value: waktuBagian,
                      elevation: 16,
                      onChanged: (String? value) {
                        if (value != null) {
                          setState(() {
                            waktuBagian = value;
                          });
                        }
                      },
                      items: listWaktuBagian.map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(
                            value,
                            style: const TextStyle(
                              fontSize: 25,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            searchField(),
            const SizedBox(height: 20),
            const Text(
              "List Dogs Breeds",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            Expanded(
              child: FutureBuilder<List<DogBreed>>(
                // ✅ PERBAIKAN 6: Gunakan Future yang sama, tidak dibuat ulang
                future: _breedsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Text('Error: ${snapshot.error}'),
                    );
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text('Data kosong'));
                  }

                  final breeds = snapshot.data!;

                  return GridView.builder(
                    itemCount: breeds.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2),
                    itemBuilder: (context, index) {
                      final breed = breeds[index];
                      return InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  DogBreedDetailScreen(apiBreed: breed),
                            ),
                          );
                        },
                        child: Card(
                          // ✅ PERBAIKAN 7: Tambahkan key unik
                          key: ValueKey('${breed.name}_$index'),
                          child: Column(
                            children: [
                              Expanded(
                                // ✅ PERBAIKAN 8: Gunakan RepaintBoundary untuk isolasi repaint
                                child: RepaintBoundary(
                                  child: breed.imageUrl != null &&
                                          breed.imageUrl!.isNotEmpty
                                      ? CachedNetworkImage(
                                          // ✅ PERBAIKAN 9: Gunakan CachedNetworkImage
                                          imageUrl: breed.imageUrl!,
                                          fit: BoxFit.cover,
                                          width: double.infinity,
                                          placeholder: (context, url) =>
                                              Container(
                                            color: Colors.grey[200],
                                            child: const Center(
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                              ),
                                            ),
                                          ),
                                          errorWidget: (context, url, error) =>
                                              Container(
                                            color: Colors.grey[300],
                                            child: const Center(
                                              child: Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Icon(Icons.error,
                                                      color: Colors.grey),
                                                  Text('Failed to load',
                                                      style: TextStyle(
                                                          fontSize: 12)),
                                                ],
                                              ),
                                            ),
                                          ),
                                          // ✅ PERBAIKAN 10: Smooth transition tanpa flicker
                                          fadeInDuration:
                                              Duration(milliseconds: 200),
                                          fadeOutDuration:
                                              Duration(milliseconds: 100),
                                          // ✅ PERBAIKAN 11: Optimalkan memory cache
                                          memCacheWidth: 300,
                                          memCacheHeight: 300,
                                        )
                                      : Container(
                                          color: Colors.grey[300],
                                          child: const Center(
                                            child: Text('No Image'),
                                          ),
                                        ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8.0),
                                child: Text(
                                  breed.name,
                                  style: const TextStyle(fontSize: 16),
                                  textAlign: TextAlign.center,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(height: 10),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
