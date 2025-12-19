import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rientro/core/theme/app_theme.dart';
import 'package:rientro/core/constants/app_strings.dart';
import 'package:rientro/core/utils/haptics.dart';
import 'package:rientro/features/contacts/providers/contacts_provider.dart';
import 'package:rientro/models/emergency_contact_model.dart';
import 'package:rientro/widgets/common/app_card.dart';
import 'package:rientro/widgets/common/app_button.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactsScreen extends ConsumerWidget {
  const ContactsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contacts = ref.watch(contactsListProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text(AppStrings.emergencyContacts),
      ),
      body: contacts.when(
        data: (list) => list.isEmpty 
            ? _EmptyState(onAdd: () => _showAddContactSheet(context, ref))
            : _ContactsList(
                contacts: list,
                onAdd: () => _showAddContactSheet(context, ref),
              ),
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppTheme.accent),
        ),
        error: (_, __) => const Center(
          child: Text(AppStrings.errorGeneric),
        ),
      ),
      floatingActionButton: contacts.value?.isNotEmpty == true
          ? FloatingActionButton(
              onPressed: () => _showAddContactSheet(context, ref),
              backgroundColor: AppTheme.accent,
              child: const Icon(
                Icons.add,
                color: AppTheme.textOnAccent,
              ),
            )
          : null,
    );
  }

  void _showAddContactSheet(BuildContext context, WidgetRef ref) {
    Haptics.light();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _AddContactSheet(),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;

  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: AppTheme.paddingPage,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppTheme.surfaceHighlight,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.people_outline,
              size: 48,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            AppStrings.noContacts,
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            AppStrings.addContactHint,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          AppPrimaryButton(
            label: AppStrings.addContact,
            icon: Icons.person_add_outlined,
            onPressed: onAdd,
          ),
        ],
      ),
    );
  }
}

class _ContactsList extends ConsumerWidget {
  final List<EmergencyContactModel> contacts;
  final VoidCallback onAdd;

  const _ContactsList({
    required this.contacts,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView.builder(
      padding: AppTheme.paddingPage,
      itemCount: contacts.length,
      itemBuilder: (context, index) {
        final contact = contacts[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _ContactTile(
            contact: contact,
            onEdit: () => _showEditContactSheet(context, ref, contact),
            onDelete: () => _showDeleteConfirm(context, ref, contact),
          ),
        );
      },
    );
  }

  void _showEditContactSheet(
    BuildContext context,
    WidgetRef ref,
    EmergencyContactModel contact,
  ) {
    Haptics.light();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddContactSheet(editContact: contact),
    );
  }

  void _showDeleteConfirm(
    BuildContext context,
    WidgetRef ref,
    EmergencyContactModel contact,
  ) {
    Haptics.warning();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Elimina contatto'),
        content: Text('Sei sicuro di voler eliminare ${contact.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(AppStrings.cancel),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(contactsActionsProvider).deleteContact(contact.id);
              Haptics.medium();
            },
            style: TextButton.styleFrom(foregroundColor: AppTheme.error),
            child: const Text(AppStrings.delete),
          ),
        ],
      ),
    );
  }
}

class _ContactTile extends StatelessWidget {
  final EmergencyContactModel contact;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ContactTile({
    required this.contact,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onEdit,
      child: Row(
        children: [
          // Avatar
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: contact.isPrimary 
                  ? AppTheme.accent.withOpacity(0.15) 
                  : AppTheme.surfaceHighlight,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                contact.initials,
                style: TextStyle(
                  color: contact.isPrimary 
                      ? AppTheme.accent 
                      : AppTheme.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        contact.name,
                        style: Theme.of(context).textTheme.titleMedium,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (contact.isPrimary) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.accent.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Primario',
                          style: TextStyle(
                            color: AppTheme.accent,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  contact.formattedPhone,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          
          // Actions
          IconButton(
            onPressed: () async {
              Haptics.light();
              final uri = Uri(scheme: 'tel', path: contact.phoneNumber);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri);
              }
            },
            icon: const Icon(
              Icons.phone_outlined,
              color: AppTheme.accent,
            ),
          ),
          
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'edit') {
                onEdit();
              } else if (value == 'delete') {
                onDelete();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit_outlined, size: 20),
                    SizedBox(width: 12),
                    Text('Modifica'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, size: 20, color: AppTheme.error),
                    SizedBox(width: 12),
                    Text('Elimina', style: TextStyle(color: AppTheme.error)),
                  ],
                ),
              ),
            ],
            icon: const Icon(
              Icons.more_vert,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _AddContactSheet extends ConsumerStatefulWidget {
  final EmergencyContactModel? editContact;

  const _AddContactSheet({this.editContact});

  @override
  ConsumerState<_AddContactSheet> createState() => _AddContactSheetState();
}

class _AddContactSheetState extends ConsumerState<_AddContactSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  bool _isPrimary = false;
  bool _isLoading = false;

  bool get _isEditing => widget.editContact != null;

  @override
  void initState() {
    super.initState();
    if (widget.editContact != null) {
      _nameController.text = widget.editContact!.name;
      _phoneController.text = widget.editContact!.phoneNumber;
      _emailController.text = widget.editContact!.email ?? '';
      _isPrimary = widget.editContact!.isPrimary;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    Haptics.medium();

    try {
      final actions = ref.read(contactsActionsProvider);
      
      if (_isEditing) {
        await actions.updateContact(
          widget.editContact!.id,
          name: _nameController.text.trim(),
          phoneNumber: _phoneController.text.trim(),
          email: _emailController.text.trim().isEmpty 
              ? null 
              : _emailController.text.trim(),
          isPrimary: _isPrimary,
        );
      } else {
        await actions.addContact(
          name: _nameController.text.trim(),
          phoneNumber: _phoneController.text.trim(),
          email: _emailController.text.trim().isEmpty 
              ? null 
              : _emailController.text.trim(),
          isPrimary: _isPrimary,
        );
      }

      if (mounted) {
        Navigator.pop(context);
        Haptics.success();
      }
    } catch (e) {
      Haptics.error();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(AppStrings.errorGeneric),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;
    
    return Container(
      margin: EdgeInsets.only(bottom: bottomPadding),
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusXLarge),
        ),
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          24,
          16,
          24,
          24 + MediaQuery.of(context).padding.bottom,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceHighlight,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Title
              Text(
                _isEditing ? AppStrings.editContact : AppStrings.addContact,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              
              const SizedBox(height: 24),
              
              // Name
              TextFormField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: AppStrings.contactName,
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Inserisci un nome';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 16),
              
              // Phone
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: AppStrings.contactPhone,
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
                validator: (value) {
                  if (value == null || value.trim().length < 8) {
                    return 'Inserisci un numero valido';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 16),
              
              // Email (optional)
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: AppStrings.contactEmail,
                  prefixIcon: Icon(Icons.email_outlined),
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Primary toggle
              SwitchListTile(
                value: _isPrimary,
                onChanged: (value) {
                  Haptics.selection();
                  setState(() => _isPrimary = value);
                },
                title: const Text('Contatto primario'),
                subtitle: const Text(
                  'Verrà contattato per primo in caso di emergenza',
                ),
                contentPadding: EdgeInsets.zero,
              ),
              
              const SizedBox(height: 24),
              
              // Save button
              AppPrimaryButton(
                label: _isEditing ? AppStrings.save : AppStrings.addContact,
                onPressed: _isLoading ? null : _save,
                isLoading: _isLoading,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

