# Finch

## A social feed for your real friends. No ads. No algorithm. No corporation.

### The problem

Social media is making people miserable and everyone knows it. A third of Gen Z deleted a social media app in the past year. People describe Instagram as performing for an audience. TikTok as an attention shredder. Discord as a place where strangers show up in your group chat. They don't want more social media. They want less — but they can't leave because that's where their friends are.

The platforms know this. They don't care. Your attention is their product. Every design decision — the infinite scroll, the algorithmic feed, the notification bombardment, the suggested content from strangers — exists to keep you on the app longer so they can sell more ads. Your wellbeing is a cost center.

### The insight

The people who want out aren't looking for a better algorithm. They're looking for the thing social media replaced: a space with your actual friends where nobody else is watching. No audience. No performance. No strangers. No ads. No content optimized to make you feel bad about yourself so you keep scrolling.

That space used to be your friend's living room. Finch is the digital version.

### The product

Finch is a private social feed shared with the people you choose. You post photos and captions. Your friends see them. That's it.

- **No algorithm.** Chronological feed. What your friends posted, in order.
- **No ads.** Ever. Finch is free and will never charge money or sell data.
- **No strangers.** You add friends by scanning a QR code or tapping an invite link. There is no explore page, no suggested users, no way for anyone to find you unless you give them your link.
- **No corporation.** Your posts live on your phone, not on a company's server. There is no Finch server. There is no company between you and your friends. When you share a photo, it goes from your phone to theirs. That's the whole path.
- **No addictive design.** No infinite scroll. No push notifications begging you to come back. Posts arrive when your friends are around, not engineered to interrupt your day.

### How it works

You install the app. It generates a cryptographic identity on your phone (you never see this — it just happens). You pick a name and an avatar. You're in.

To add a friend, you share an invite link or scan a QR code. When they accept, you exchange encryption keys — again, invisible to you. Now you can see each other's posts. Everything is encrypted end-to-end. Not because of a privacy policy that can change, but because of math that can't.

Your phone runs a tiny server in the background. When a friend opens Finch, their phone talks directly to yours (over your local WiFi if you're nearby, or over the internet via Tor if you're not). They pull your latest posts, decrypt them, and see them in their feed. No middleman. No server. No company storing your photos.

### What it feels like

You open Finch a few times a day. You see what your friends posted. Maybe you leave a comment or a reaction. You post a photo from your day. Then you close it.

There's no feed that refreshes forever. No recommended content. No notification pulling you back in. It's calm. It's small. It's yours.

Sometimes a post takes a few minutes to show up because your friend's phone was off. That's fine. This isn't designed to be instant. It's designed to not ruin your brain.

### Why not just use Instagram Close Friends / BeReal / Favs?

**Instagram Close Friends** is still Instagram. Meta owns your data. The algorithm still runs your main feed. You're one tap away from the content machine. And Meta can change how Close Friends works whenever they want.

**BeReal** was supposed to be the anti-Instagram. It peaked at 73 million users, crashed, and started running ads in 2025. That's the lifecycle of every VC-funded "we're different" social app. They need to make money eventually, and the only way to make money on social media is to sell attention.

**Favs** is the closest to what Finch is trying to be — private, friends-only, no algorithm. It's good. But it's a centralized service backed by venture capital. Your data lives on their servers. Their privacy promise is a policy document, not an architectural guarantee. One acquisition and your "private" posts belong to whoever bought the company.

Finch can't decay this way because there's nothing to acquire. There are no servers to sell. No data to monetize. No company to buy. The app is the entire product, and it runs on your phone.

### Why now

Three things are converging:

1. **The backlash is real.** People aren't just complaining about social media — they're deleting it. A third of Gen Z left a platform in the past year. Governments are legislating. The demand for something different is genuine and growing.

2. **The technology is ready.** Embedded Tor clients (Arti) make it possible to run a reachable server on a phone without any infrastructure. Five years ago this wasn't practical. Now it is.

3. **The alternatives are failing.** BeReal has ads. Every VC-funded "private social" app will follow the same path. The only way to build something that stays private is to build something that has no business model to corrupt it.

### The bigger picture

Finch is the first step in a larger vision: making self-hosting normal.

Today, every meaningful digital interaction goes through a corporation's server. Your photos, your messages, your email, your payments — all stored on hardware you don't control, governed by terms you didn't read, subject to changes you can't prevent.

It doesn't have to be this way. The technology to own your own digital life exists. It's just been too hard to use.

Finch starts with the simplest possible case: a social feed that runs on your phone. No server to set up. No configuration. It just works. But if you want more availability — say, your posts to be reachable even when your phone is off — you can install Finch on an old phone and turn it into your personal server. One QR scan, one toggle. Now your content is available 24/7, running on hardware in your house.

That's the first step. Once someone has a device running their social feed, adding messaging is natural. Then media storage. Then more. Each step is optional. Each step gives the user more control over their digital life. And none of it requires trusting a corporation.

The identity, encryption, and networking stack that Finch builds is the foundation for all of it.

### What we're building

**Phase 1** (the thing that ships):
- Post photos with captions to a private, friends-only feed
- Add friends via QR code or invite link
- End-to-end encrypted — your phone to theirs, no middleman
- Comments and reactions
- Works over WiFi (instant) and internet (via Tor, a few seconds)
- Feed key rotation: revoke access when you remove a friend
- Spare-device relay: turn an old phone into your personal always-on server
- Free. Open source. No account required beyond installing the app.

**Phase 2** (what comes next):
- Standalone relay: Rust binary for Raspberry Pi / VPS / self-hosters
- Multi-device support: same identity on phone and laptop
- Direct messaging

### Who this is for

Finch is for anyone who wants a quieter, more private way to share with their friends. But it's especially for:

- **People who are done with algorithmic social media** and want a private space that doesn't exploit them
- **Friend groups** who want a shared feed without the noise of a platform
- **Anyone who's ever thought** "I wish I could share this with just my actual friends, not the entire internet"

It's not for people who want to go viral, build a following, or consume content from strangers. There's no path to that in Finch, by design.

### The trade-offs (honest version)

Finch is slower than Instagram. Posts don't appear instantly — they appear when your phone and your friend's phone are both awake. Sometimes that's seconds. Sometimes it's hours. If you want real-time delivery, a spare-device relay solves that, but the phone-only experience is intentionally async.

There are no push notifications. Nobody buzzes your phone to pull you back in. You check Finch when you want to, not when it tells you to.

If you lose your phone and didn't save your recovery phrase, your identity is gone. There is no "forgot password" because there is no server that knows who you are.

These aren't limitations we're embarrassed about. They're choices. A social feed that demands your constant attention isn't private — it's just a different kind of exploitation.
