# TopView

A Flutter portfolio tracking application for NEPSE that automatically parses broker SMS messages to track stock transactions and show them in organized format.


### First Time Setup

1. Grant SMS permissions when prompted
2. The app will automatically scan your SMS messages for broker transactions
3. Select your client ID from the dropdown
4. View your portfolio and transaction history

## Parsing Format

The app can parse SMS messages from various brokers that follow standard formats. Currently optimized for:
- Broker messages with format: "BNo.XX Purchased/Sold on DATE (SYMBOL XX kitta @ PRICE)"
- Multiple stock transactions in single SMS
- Client ID extraction from messages


## Privacy & Security

- All data stored locally on your device
- No data transmitted to external servers
- SMS permissions used only for parsing broker messages


## Limitations

- No info about current market value of scrips (Implemented partially)
- No info about stock divident and adjustments
- No info about IPOS and Right shares too
- Broker commissions aren't taken into consideration
- Incomplete design and development atp