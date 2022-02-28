import Peanuts.Fades.FadeManagerComponent;

/*
    Fade a specific player's screen to black. If the duration is negative,
    the fade will last indefinitely, until it is cleared. Otherwise, it
    will automatically fade back in after the duration.
*/
UFUNCTION(Category = "Fade")
void FadeOutPlayer(AHazePlayerCharacter PlayerCharacter, float FadeDuration = -1.f, float FadeOutTime = 0.5f, float FadeInTime = 0.5f)
{
    auto Manager = UFadeManagerComponent::GetOrCreate(PlayerCharacter);
    Manager.AddFade(FadeDuration, FadeOutTime, FadeInTime, EFadePriority::Gameplay);
}

UFUNCTION(Category = "Fade")
void ClearPlayerFades(AHazePlayerCharacter PlayerCharacter, float FadeInTime = 0.5f)
{
    auto Manager = UFadeManagerComponent::GetOrCreate(PlayerCharacter);
    Manager.ClearAllFades(FadeInTime, EFadePriority::Gameplay);
}

/*
    Fade both players' screens to black, overriding any individual fades they already have.
*/
UFUNCTION(Category = "Fade")
void FadeOutFullscreen(float FadeDuration = -1.f, float FadeOutTime = 0.5f, float FadeInTime = 0.5f)
{
    for (auto Player : Game::GetPlayers())
    {
        auto Manager = UFadeManagerComponent::GetOrCreate(Player);
        Manager.AddFade(FadeDuration, FadeOutTime, FadeInTime, EFadePriority::Fullscreen);
    }
}

UFUNCTION(Category = "Fade")
void ClearFullscreenFades(float FadeInTime = 0.5f)
{
    for (auto Player : Game::GetPlayers())
    {
        auto Manager = UFadeManagerComponent::GetOrCreate(Player);
        Manager.ClearAllFades(FadeInTime, EFadePriority::Fullscreen);
    }
}

/* Fade the whole screen to a specific color. */
UFUNCTION(Category = "Fade")
void FadeScreenToColor(FLinearColor FadeColor, float FadeDuration = -1.f, float FadeOutTime = 0.5f, float FadeInTime = 0.5f)
{
    for (auto Player : Game::GetPlayers())
    {
        auto Manager = UFadeManagerComponent::GetOrCreate(Player);
        Manager.AddFadeToColor(FadeColor, FadeDuration, FadeOutTime, FadeInTime, EFadePriority::Fullscreen);
    }
}

/* Fade a player's screen to a specific color. */
UFUNCTION(Category = "Fade")
void FadePlayerToColor(AHazePlayerCharacter PlayerCharacter, FLinearColor FadeColor, float FadeDuration = -1.f, float FadeOutTime = 0.5f, float FadeInTime = 0.5f)
{
    auto Manager = UFadeManagerComponent::GetOrCreate(PlayerCharacter);
    Manager.AddFadeToColor(FadeColor, FadeDuration, FadeOutTime, FadeInTime, EFadePriority::Gameplay);
}