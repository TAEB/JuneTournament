use inc::Module::Install;

name        'JuneTournament';
version     '0.01';
requires    'Jifty' => '0.80311';

requires 'Text::XLogfile' => '0.04';
requires 'parent';

WriteAll;
