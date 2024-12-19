import Array "mo:base/Array";

import HashMap "mo:base/HashMap";

import Nat "mo:base/Nat";
import Principal "mo:base/Principal";
import Text "mo:base/Text";
import Time "mo:base/Time";
import Buffer "mo:base/Buffer";
import Int "mo:base/Int";

actor DatingApp {
   
    type ProfileId = Principal;
    
    type Profile = {
        id: ProfileId;
        name: Text;
        bio: Text;
        interests: [Text];
        nftProfileUrl: Text;
        isVerified: Bool;
        createdAt: Time.Time;
        reputation: Nat;
    };

    type Message = {
        from: ProfileId;
        to: ProfileId;
        content: Text;
        timestamp: Time.Time;
    };

    type Match = {
        profile1: ProfileId;
        profile2: ProfileId;
        status: MatchStatus;
        timestamp: Time.Time;
    };

    type MatchStatus = {
        #pending;
        #accepted;
        #rejected;
    };

    type VaultContent = {
        id: Text;
        content: Text;
        contentType: Text;
        timestamp: Time.Time;
        isVisible: Bool;
    };

    // State
    private var profiles = HashMap.HashMap<ProfileId, Profile>(0, Principal.equal, Principal.hash);
    private var matches = HashMap.HashMap<Text, Match>(0, Text.equal, Text.hash);
    private  var messages = Buffer.Buffer<Message>(0);
    private var vaultContents = HashMap.HashMap<Text, VaultContent>(0, Text.equal, Text.hash);

    // Profile Management
    public shared(msg) func createProfile(name: Text, bio: Text, interests: [Text], nftUrl: Text) : async Bool {
        let caller = msg.caller;
        
        let newProfile: Profile = {
            id = caller;
            name = name;
            bio = bio;
            interests = interests;
            nftProfileUrl = nftUrl;
            isVerified = false;
            createdAt = Time.now();
            reputation = 0;
        };

        profiles.put(caller, newProfile);
        return true;
    };

    public shared(msg) func verifyProfile() : async Bool {
        let caller = msg.caller;
        switch (profiles.get(caller)) {
            case null { return false; };
            case (?profile) {
                let updatedProfile = {
                    id = profile.id;
                    name = profile.name;
                    bio = profile.bio;
                    interests = profile.interests;
                    nftProfileUrl = profile.nftProfileUrl;
                    isVerified = true;
                    createdAt = profile.createdAt;
                    reputation = profile.reputation;
                };
                profiles.put(caller, updatedProfile);
                return true;
            };
        };
    };

    // Matchmaking its not working i tried but i wrote same interests.
    public shared(msg) func findMatches() : async [Profile] {
        let caller = msg.caller;
        let matches = Buffer.Buffer<Profile>(0);
        
        switch (profiles.get(caller)) {
            case null { return []; };
            case (?userProfile) {
                for ((id, profile) in profiles.entries()) {
                    if (id != caller and hasCommonInterests(userProfile.interests, profile.interests)) {
                        matches.add(profile);
                    };
                };
            };
        };
        
        return Buffer.toArray(matches);
    };

    private func hasCommonInterests(interests1: [Text], interests2: [Text]) : Bool {
        for (interest1 in interests1.vals()) {
            for (interest2 in interests2.vals()) {
                if (interest1 == interest2) {
                    return true;
                };
            };
        };
        return false;
    };

    // Messaging
    public shared(msg) func sendMessage(to: ProfileId, content: Text) : async Bool {
        let message: Message = {
            from = msg.caller;
            to = to;
            content = content;
            timestamp = Time.now();
        };
        
        messages.add(message);
        return true;
    };


public shared query(msg) func getMessages(otherProfileId: ProfileId) : async [Message] {
    let caller = msg.caller;
    let allMessages = Buffer.toArray(messages);
    return Array.filter(allMessages, func (m: Message): Bool {
        (m.from == caller and m.to == otherProfileId) or
        (m.from == otherProfileId and m.to == caller)
    });
};



    // Love Vault
    public shared(msg) func addToVault(content: Text, contentType: Text) : async Text {
        let id = Text.concat(Principal.toText(msg.caller), Int.toText(Time.now()));
        let vaultContent: VaultContent = {
            id = id;
            content = content;
            contentType = contentType;
            timestamp = Time.now();
            isVisible = true;
        };
        
        vaultContents.put(id, vaultContent);
        return id;
    };

    public shared(msg) func hideVaultContent(id: Text) : async Bool {
        switch (vaultContents.get(id)) {
            case null { return false; };
            case (?content) {
                let updatedContent: VaultContent = {
                    id = content.id;
                    content = content.content;
                    contentType = content.contentType;
                    timestamp = content.timestamp;
                    isVisible = false;
                };
                vaultContents.put(id, updatedContent);
                return true;
            };
        };
    };
};