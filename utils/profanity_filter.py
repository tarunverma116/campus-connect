BLOCKED_WORDS = {"fuck","shit","bitch","asshole","bastard","cunt","dick","pussy","slut","whore","nigger","nigga","faggot","retard","kys"}
def contains_profanity(text):
    lower = text.lower()
    for word in lower.split():
        if word.strip(".,!?;:'\"()[]{}") in BLOCKED_WORDS:
            return True
    return "kill yourself" in lower
