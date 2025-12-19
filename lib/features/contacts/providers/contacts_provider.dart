import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rientro/services/contacts_service.dart';
import 'package:rientro/models/emergency_contact_model.dart';
import 'package:rientro/features/auth/providers/auth_provider.dart';

/// Provider del servizio contatti
final contactsServiceProvider = Provider<ContactsService>((ref) {
  return ContactsService();
});

/// Provider della lista contatti
final contactsListProvider = StreamProvider<List<EmergencyContactModel>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value([]);
  
  final contactsService = ref.watch(contactsServiceProvider);
  return contactsService.getContactsStream(user.uid);
});

/// Provider per verificare se l'utente ha contatti
final hasContactsProvider = Provider<bool>((ref) {
  final contacts = ref.watch(contactsListProvider).value ?? [];
  return contacts.isNotEmpty;
});

/// Provider conteggio contatti
final contactsCountProvider = Provider<int>((ref) {
  final contacts = ref.watch(contactsListProvider).value ?? [];
  return contacts.length;
});

/// Provider contatto primario
final primaryContactProvider = Provider<EmergencyContactModel?>((ref) {
  final contacts = ref.watch(contactsListProvider).value ?? [];
  if (contacts.isEmpty) return null;
  return contacts.firstWhere(
    (c) => c.isPrimary,
    orElse: () => contacts.first,
  );
});

/// Provider per le azioni sui contatti
final contactsActionsProvider = Provider<ContactsActions>((ref) {
  final contactsService = ref.watch(contactsServiceProvider);
  final user = ref.watch(currentUserProvider);
  return ContactsActions(
    contactsService: contactsService,
    userId: user?.uid,
  );
});

/// Classe per le azioni sui contatti
class ContactsActions {
  final ContactsService contactsService;
  final String? userId;

  ContactsActions({
    required this.contactsService,
    this.userId,
  });

  /// Aggiungi contatto
  Future<EmergencyContactModel?> addContact({
    required String name,
    required String phoneNumber,
    String? email,
    bool isPrimary = false,
  }) async {
    if (userId == null) return null;
    
    return contactsService.addContact(
      userId: userId!,
      name: name,
      phoneNumber: phoneNumber,
      email: email,
      isPrimary: isPrimary,
    );
  }

  /// Aggiorna contatto
  Future<void> updateContact(
    String contactId, {
    String? name,
    String? phoneNumber,
    String? email,
    bool? isPrimary,
  }) async {
    await contactsService.updateContact(
      contactId,
      name: name,
      phoneNumber: phoneNumber,
      email: email,
      isPrimary: isPrimary,
    );
  }

  /// Elimina contatto
  Future<void> deleteContact(String contactId) async {
    await contactsService.deleteContact(contactId);
  }

  /// Imposta come primario
  Future<void> setPrimary(String contactId) async {
    await contactsService.updateContact(contactId, isPrimary: true);
  }
}

/// Provider per il form di modifica contatto
final contactFormProvider = StateNotifierProvider.autoDispose<ContactFormNotifier, ContactForm>((ref) {
  return ContactFormNotifier();
});

class ContactForm {
  final String name;
  final String phoneNumber;
  final String email;
  final bool isPrimary;
  final bool isValid;

  const ContactForm({
    this.name = '',
    this.phoneNumber = '',
    this.email = '',
    this.isPrimary = false,
    this.isValid = false,
  });

  ContactForm copyWith({
    String? name,
    String? phoneNumber,
    String? email,
    bool? isPrimary,
  }) {
    final newName = name ?? this.name;
    final newPhone = phoneNumber ?? this.phoneNumber;
    
    return ContactForm(
      name: newName,
      phoneNumber: newPhone,
      email: email ?? this.email,
      isPrimary: isPrimary ?? this.isPrimary,
      isValid: newName.trim().isNotEmpty && newPhone.trim().length >= 8,
    );
  }
}

class ContactFormNotifier extends StateNotifier<ContactForm> {
  ContactFormNotifier() : super(const ContactForm());

  void setName(String name) {
    state = state.copyWith(name: name);
  }

  void setPhoneNumber(String phone) {
    state = state.copyWith(phoneNumber: phone);
  }

  void setEmail(String email) {
    state = state.copyWith(email: email);
  }

  void setIsPrimary(bool value) {
    state = state.copyWith(isPrimary: value);
  }

  void loadContact(EmergencyContactModel contact) {
    state = ContactForm(
      name: contact.name,
      phoneNumber: contact.phoneNumber,
      email: contact.email ?? '',
      isPrimary: contact.isPrimary,
      isValid: true,
    );
  }

  void reset() {
    state = const ContactForm();
  }
}

/// Provider per i contatti selezionati (per nuovo rientro)
final selectedContactsProvider = StateProvider<Set<String>>((ref) => {});

