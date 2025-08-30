import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/secure_email_service.dart';
import 'security_info_widget.dart';

class EmailAccountsPage extends StatefulWidget {
  const EmailAccountsPage({super.key});

  @override
  State<EmailAccountsPage> createState() => _EmailAccountsPageState();
}

class _EmailAccountsPageState extends State<EmailAccountsPage> {
  List<Map<String, dynamic>> _emailAccounts = [];
  bool _isLoading = true;
  String? _error;
  
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _displayNameController = TextEditingController();
  final _providerController = TextEditingController();
  
  bool _isPasswordVisible = false;
  bool _isAddingAccount = false;
  bool _isEditing = false;
  String? _editingEmail;

  @override
  void initState() {
    super.initState();
    _loadEmailAccounts();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _displayNameController.dispose();
    _providerController.dispose();
    super.dispose();
  }

  Future<void> _loadEmailAccounts() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final accounts = await SecureEmailService.getAllEmailAccounts();
      setState(() {
        _emailAccounts = accounts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _showAddAccountDialog() {
    _resetForm();
    _isEditing = false;
    _editingEmail = null;
    _showAccountDialog();
  }

  void _showEditAccountDialog(Map<String, dynamic> account) {
    _emailController.text = account['email'];
    _passwordController.text = account['password'];
    _displayNameController.text = account['displayName'] ?? '';
    _providerController.text = account['provider'] ?? '';
    
    _isEditing = true;
    _editingEmail = account['email'];
    _showAccountDialog();
  }

  void _showAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_isEditing ? 'Email Hesabını Düzenle' : 'Yeni Email Hesabı Ekle'),
        content: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email Adresi',
                    hintText: 'ornek@email.com',
                    prefixIcon: Icon(Icons.email),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Email adresi gerekli';
                    }
                    if (!value.contains('@')) {
                      return 'Geçerli bir email adresi girin';
                    }
                    return null;
                  },
                  enabled: !_isEditing, // Düzenleme sırasında email değiştirilemez
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: 'Şifre',
                    hintText: '••••••••',
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _isPasswordVisible = !_isPasswordVisible;
                        });
                      },
                    ),
                  ),
                  obscureText: !_isPasswordVisible,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Şifre gerekli';
                    }
                    if (value.length < 6) {
                      return 'Şifre en az 6 karakter olmalı';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _displayNameController,
                  decoration: const InputDecoration(
                    labelText: 'Görünen Ad (Opsiyonel)',
                    hintText: 'Kişisel hesap',
                    prefixIcon: Icon(Icons.person),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _providerController,
                  decoration: const InputDecoration(
                    labelText: 'Sağlayıcı (Opsiyonel)',
                    hintText: 'gmail.com, outlook.com',
                    prefixIcon: Icon(Icons.business),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: _isAddingAccount ? null : _saveAccount,
            child: _isAddingAccount
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(_isEditing ? 'Güncelle' : 'Ekle'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveAccount() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isAddingAccount = true;
    });

    try {
      if (_isEditing) {
        await SecureEmailService.updateEmailAccount(
          email: _editingEmail!,
          password: _passwordController.text,
          displayName: _displayNameController.text.isEmpty ? null : _displayNameController.text,
          provider: _providerController.text.isEmpty ? null : _providerController.text,
        );
      } else {
        await SecureEmailService.addEmailAccount(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          displayName: _displayNameController.text.isEmpty ? null : _displayNameController.text,
          provider: _providerController.text.isEmpty ? null : _providerController.text,
        );
      }

      Navigator.of(context).pop();
      _loadEmailAccounts();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditing ? 'Email hesabı güncellendi' : 'Email hesabı eklendi'),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      setState(() {
        _isAddingAccount = false;
      });
    }
  }

  void _resetForm() {
    _emailController.clear();
    _passwordController.clear();
    _displayNameController.clear();
    _providerController.clear();
    _isPasswordVisible = false;
  }

  Future<void> _deleteAccount(String email) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hesabı Sil'),
        content: Text('$email hesabını silmek istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Sil'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await SecureEmailService.deleteEmailAccount(email);
        _loadEmailAccounts();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$email hesabı silindi'),
              backgroundColor: Theme.of(context).colorScheme.primary,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Hata: $e'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    }
  }

  Future<void> _copyToClipboard(String text, String label) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$label panoya kopyalandı'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Email Hesapları'),
        actions: [
          IconButton(
            onPressed: _loadEmailAccounts,
            icon: const Icon(Icons.refresh),
            tooltip: 'Yenile',
          ),
        ],
      ),
      body: Column(
        children: [
          // Güvenlik bilgisi
          const SecurityInfoWidget(),
          
          // Email hesapları listesi
          Expanded(
            child: _buildEmailAccountsList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddAccountDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmailAccountsList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Hata oluştu',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadEmailAccounts,
              child: const Text('Tekrar Dene'),
            ),
          ],
        ),
      );
    }
    
    if (_emailAccounts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.email_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'Henüz email hesabı eklenmemiş',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Güvenli bir şekilde email hesaplarınızı saklayın',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _emailAccounts.length,
      itemBuilder: (context, index) {
        final account = _emailAccounts[index];
        final lastUsed = DateTime.parse(account['lastUsed']);
        
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: Text(
                (account['displayName'] ?? account['email'].split('@')[0])
                    .substring(0, 1)
                    .toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              account['displayName'] ?? account['email'].split('@')[0],
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(account['email']),
                if (account['provider'] != null)
                  Text(
                    'Sağlayıcı: ${account['provider']}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                Text(
                  'Son kullanım: ${_formatDate(lastUsed)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            trailing: PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case 'edit':
                    _showEditAccountDialog(account);
                    break;
                  case 'copy_email':
                    _copyToClipboard(account['email'], 'Email adresi');
                    break;
                  case 'copy_password':
                    _copyToClipboard(account['password'], 'Şifre');
                    break;
                  case 'delete':
                    _deleteAccount(account['email']);
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit),
                      SizedBox(width: 8),
                      Text('Düzenle'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'copy_email',
                  child: Row(
                    children: [
                      Icon(Icons.copy),
                      SizedBox(width: 8),
                      Text('Email\'i Kopyala'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'copy_password',
                  child: Row(
                    children: [
                      Icon(Icons.copy),
                      SizedBox(width: 8),
                      Text('Şifreyi Kopyala'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Sil', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
            onTap: () {
              _showEditAccountDialog(account);
            },
          ),
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return 'Bugün';
    } else if (difference.inDays == 1) {
      return 'Dün';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} gün önce';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
} 