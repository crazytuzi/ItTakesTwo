struct FCurrentFade
{
    float Duration = 0.f;
    float Time = 0.f;
    float FadeInTime = 0.f;
    float FadeOutTime = 0.f;
	FLinearColor FadeColor;
    EFadePriority Priority = EFadePriority::MAX;
};

const int EXTRA_LOADING_SCREEN_FADE_FRAMES = 3;
const float LOADING_SCREEN_FADE_IN_LENGTH = 0.5f;

const FConsoleVariable CVar_MinimumLoadingScreenTime("Haze.MinimumLoadingScreenTime", 1.f);

UCLASS(NotPlaceable, NotBlueprintable)
class UFadeManagerComponent : UHazeFadeManagerComponent
{
	default PrimaryComponentTick.bTickEvenWhenPaused = true;
	default PrimaryComponentTick.TickGroup = ETickingGroup::TG_PostPhysics;

    TArray<FCurrentFade> Fades;
	UPROPERTY(BlueprintReadOnly)
    float CurrentFadeAlpha = 0.f;
	FLinearColor CurrentFadeColor;

	FLinearColor LoadingScreenFadeColor = FLinearColor::Black;
	int LoadingScreenRemainingFrames = 0;
	bool bIsFadingFromLoading = false;

	bool bIsInLoadingScreen = false;
	bool bWasFadedOutBeforeLoadingScreen = false;

	AHazePlayerCharacter OwningPlayer = nullptr;
	AHazeMenuCameraUser OwningMenuCameraUser = nullptr;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		// Register this as a persistent component, we don't want to automatically
		// get destroyed when resets happen, we can implement our own reset for fades.
		Reset::RegisterPersistentComponent(this);

		OwningPlayer = Cast<AHazePlayerCharacter>(Owner);
		OwningMenuCameraUser = Cast<AHazeMenuCameraUser>(Owner);
	}

    void ClearAllFades_NoUpdate(float FadeInTime, EFadePriority ClearPriority = EFadePriority::Gameplay)
	{
        for (int i = 0, Count = Fades.Num(); i < Count; ++i)
        {
            // Ignore fades with a different priority than we're clearing
            if (Fades[i].Priority != ClearPriority)
                continue;

            // If our fade in time is 0, delete the fade instead, we don't need to do any blending
            if (FadeInTime <= 0.f)
            {
                Fades.RemoveAt(i);
                --i; --Count;
                continue;
            }

            // Move the fade so it is immediately at the beginning of its fade in
            Fades[i].Duration = FadeInTime;
            Fades[i].FadeInTime = FadeInTime;
            Fades[i].Time = 0.f;
        }
	}

    // Clears all fades of the specified priority
	UFUNCTION(BlueprintOverride)
    void ClearAllFades(float FadeInTime, EFadePriority ClearPriority = EFadePriority::Gameplay)
    {
		ClearAllFades_NoUpdate(FadeInTime, ClearPriority);
        UpdateFades(0.f);
    }

	UFUNCTION(BlueprintOverride)
    void AddFade(float Duration, float FadeOutTime, float FadeInTime, EFadePriority Priority = EFadePriority::Gameplay)
    {
		AddFadeToColor(FLinearColor::Black, Duration, FadeOutTime, FadeInTime, Priority);
    }

	UFUNCTION(BlueprintOverride)
    void AddFadeToColor(FLinearColor Color, float Duration, float FadeOutTime, float FadeInTime, EFadePriority Priority = EFadePriority::Gameplay)
    {
        FCurrentFade Fade;
        Fade.Duration = Duration;
        Fade.FadeInTime = FadeInTime;
        Fade.FadeOutTime = FadeOutTime;
        Fade.Time = 0.f;
        Fade.Priority = Priority;
		Fade.FadeColor = Color;
        Fades.Add(Fade);

        UpdateFades(0.f);
    }

    void UpdateFades(float DeltaSeconds)
    {
        // Each fade does its own blending of the current fade amount to their desired one,
        // then the highest fade amount among all of them is chosen.
		FLinearColor NextFadeColor = FLinearColor::Black;
        float NextFadeAlpha = 0.f;
        for (int i = 0, Count = Fades.Num(); i < Count; ++i)
        {
			auto& Fade = Fades[i];

            // Advance the fade's timer until it's reached its duration
            if (Fade.Duration >= 0.f)
            {
                Fade.Time += DeltaSeconds;
                if (Fade.Time >= Fade.Duration + Fade.FadeInTime + Fade.FadeOutTime)
                {
                    Fades.RemoveAt(i);
                    --i; --Count;
                    continue;
                }
            }

            // Determine whether we want to be faded or not right now, disregarding blend
            float TargetFadeAlpha = 1.f;
            float BlendTime = Fade.FadeOutTime;
            if (Fade.Duration >= 0.f)
            {
                // If we're fading back in
                if (Fade.Time > Fade.Duration + Fade.FadeOutTime)
                {
                    TargetFadeAlpha = 0.f;
                    BlendTime = Fade.FadeInTime;
                }
            }

            // Blend from our active fade alpha to our target using the appropriate blend speed
            float BlendedFadeAlpha = CurrentFadeAlpha;
            if (BlendTime == 0.f)
            {
                BlendedFadeAlpha = TargetFadeAlpha;
            }
            else if(DeltaSeconds != 0.f)
            {
                float MaxFadeDelta = DeltaSeconds / BlendTime;
                float FullDelta = (TargetFadeAlpha - CurrentFadeAlpha);
                BlendedFadeAlpha = CurrentFadeAlpha + FMath::Clamp(FullDelta, -MaxFadeDelta, MaxFadeDelta);
            }

            // Choose the highest blended fade alpha out of all our fades
            if (BlendedFadeAlpha > NextFadeAlpha)
			{
                NextFadeAlpha = BlendedFadeAlpha;
				NextFadeColor = Fade.FadeColor;
			}
        }

		// Apply Level Sequence Fade higher
		FHazeFadeSettings LevelSequenceSettings = AHazeLevelSequenceActor::GetFadeSettingsForFadeManagerComponent(this);
		if (LevelSequenceSettings.FadeAlpha > NextFadeAlpha)
		{
			NextFadeColor = LevelSequenceSettings.FadeColor;
			NextFadeAlpha = LevelSequenceSettings.FadeAlpha;
		}

		// If we're in a loading screen, always fully fade
		if (Game::IsInLoadingScreen())
		{
			NextFadeAlpha = 1.f;
			NextFadeColor = LoadingScreenFadeColor;

			LoadingScreenRemainingFrames = EXTRA_LOADING_SCREEN_FADE_FRAMES;
			bIsFadingFromLoading = true;
		}
		else if (LoadingScreenRemainingFrames > 0)
		{
			// Stay black for a couple of frames after a loading screen to give time for things to pop into place
			if (!Game::IsPausedForAnyReason())
				LoadingScreenRemainingFrames -= 1;

			NextFadeAlpha = 1.f;
			NextFadeColor = LoadingScreenFadeColor;

			if (LoadingScreenRemainingFrames == 0 && OwningPlayer != nullptr)
			{
				AddFadeToColor(LoadingScreenFadeColor, 0.f, 0.f, LOADING_SCREEN_FADE_IN_LENGTH, EFadePriority::Gameplay);
				System::SetTimer(this, n"OnFadeFromLoadComplete", LOADING_SCREEN_FADE_IN_LENGTH, false);
			}
		}

        // Update the player's actual fade overlay
        CurrentFadeAlpha = NextFadeAlpha;

		CurrentFadeColor = NextFadeColor;
		CurrentFadeColor.A = CurrentFadeAlpha;

		if (OwningPlayer != nullptr)
        	SceneView::SetPlayerOverlayColor(OwningPlayer, CurrentFadeColor);
		else if(OwningMenuCameraUser != nullptr)
			OwningMenuCameraUser.SetFadeOverlayColor(CurrentFadeColor);
    }

	UFUNCTION()
	void OnFadeFromLoadComplete()
	{
		if(!Game::IsInLoadingScreen())
			bIsFadingFromLoading = false;
	}

    UFUNCTION(BlueprintOverride)
    void Tick(float DeltaSeconds)
    {
        UpdateFades(DeltaSeconds);

		// Store the most recent fade color so the next loading screen can use it
		if (!Game::IsInLoadingScreen() && LoadingScreenRemainingFrames <= 0)
		{
			LoadingScreenFadeColor = CurrentFadeColor;
			LoadingScreenFadeColor.A = 1.f;
			bWasFadedOutBeforeLoadingScreen = (CurrentFadeAlpha > 0.9f);
		}

		UpdateLoadingScreenState();
    }

	void UpdateLoadingScreenState()
	{
		// When we are on a loading screen and fading to something that ISN'T black,
		// we want to display fullscreen+letterboxes to match the fade to white from the cutscene
		if (bIsInLoadingScreen != Game::IsInLoadingScreen())
		{
			bIsInLoadingScreen = Game::IsInLoadingScreen();;
			if (bIsInLoadingScreen)
			{
				if (OwningPlayer == Game::May)
				{
					if (bWasFadedOutBeforeLoadingScreen)
						Progress::SetMinimumLoadingScreenDuration(0.f);
					else
						Progress::SetMinimumLoadingScreenDuration(CVar_MinimumLoadingScreenTime.GetFloat());
				}

				if (OwningPlayer != nullptr && LoadingScreenFadeColor != FLinearColor::Black)
				{
					SceneView::ApplyPlayerLetterbox(OwningPlayer, this, EHazeViewPointBlendSpeed::Instant);
					Game::May.ApplyViewSizeOverride(this, EHazeViewPointSize::Fullscreen, EHazeViewPointBlendSpeed::Instant, EHazeViewPointPriority::Cutscene);
				}
			}
			else
			{
				if (OwningPlayer == Game::May)
				{
					Progress::SetMinimumLoadingScreenDuration(0.f);
				}

				if (OwningPlayer != nullptr)
				{
					SceneView::ClearPlayerLetterbox(OwningPlayer, this);
					Game::May.ClearViewSizeOverride(this, EHazeViewPointBlendSpeed::Instant);
				}
			}
		}
	}
    
    UFUNCTION(BlueprintOverride)
    void OnResetComponent(EComponentResetType ResetType)
    {
        // We clear everything on reset except 'Override' fades, which are persistent
        ClearAllFades_NoUpdate(0.f, EFadePriority::Gameplay);
        ClearAllFades_NoUpdate(0.f, EFadePriority::Fullscreen);

		bIsInLoadingScreen = false;
		SceneView::ClearPlayerLetterbox(OwningPlayer, this);
		Game::May.ClearViewSizeOverride(this, EHazeViewPointBlendSpeed::Instant);

		UpdateLoadingScreenState();
    }
};