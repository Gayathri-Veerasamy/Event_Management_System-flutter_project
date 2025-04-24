import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'event_detail_page.dart';

class FavouritePage extends StatelessWidget {
  final String userId;

  const FavouritePage({required this.userId, super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('favorites')
          .doc(userId)
          .collection('userFavorites')
          .snapshots(),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting)
          return Center(child: CircularProgressIndicator());
        final allDocs = snap.data!.docs;
        if (allDocs.isEmpty) return Center(child: Text("No favorites"));

        return ListView.builder(
          itemCount: allDocs.length,
          itemBuilder: (ctx, i) {
            final data = allDocs[i].data() as Map<String, dynamic>;
            final img = data['mediaUrl'] ?? '';
            return GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EventDetailPage(event: data, userId: userId),
                ),
              ),
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AspectRatio(
                      aspectRatio: 16 / 9,
                      child: img.startsWith('http')
                          ? Image.network(img, fit: BoxFit.cover)
                          : Container(color: Colors.grey[300]),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(6),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(data['name'] ?? '',
                              style: TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.bold)),
                          SizedBox(height: 4),
                          Text(data['date'] ?? '',
                              style: TextStyle(fontSize: 10)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
