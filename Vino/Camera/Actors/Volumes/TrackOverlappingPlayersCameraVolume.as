import Vino.Camera.Components.CameraKeepInViewComponent;
import Vino.Camera.Components.CameraSplineFollowerComponent;
import Vino.Camera.Components.FocusTrackerComponent;

enum EAdjustScreenSplitToOverlappingPlayers
{
	None, 	// Don't adjust screen size
	Normal, // Use normal split when one player is in volume, full screen if both.
	Large, 	// Player in volume will have a large screen when one player is in view, full screen if both. 
	Small, // Player in volume will have a small screen when one player is in view, full screen if both. 
}

// A camera volume which in addition to the usual camera activation and settings stuff will add overlapping 
// players as targets for camera components which require those, such as the KeepInView comp, FocusTracker 
// and SplineFollower. It can also controls screen split based on which players are in the volume.
class ATrackOverlappingPlayersCameraVolume : AHazeCameraVolume
{
	// Cameras will try to move around with all players inside the volume
	UPROPERTY(BlueprintReadOnly)
	bool bTrackTranslation = true;

	// Cameras will try to rotate based on positions of all players in the volume
	UPROPERTY(BlueprintReadOnly)
	bool bTrackRotation = true;

	// How should screen split be adjusted when players are in volume
	UPROPERTY(BlueprintReadOnly)
	EAdjustScreenSplitToOverlappingPlayers ScreenSplitAdjustment = EAdjustScreenSplitToOverlappingPlayers::Normal;

	// How fast we adjust view screen split
	UPROPERTY(meta = (EditCondition = "ScreenSplitAdjustment != EAdjustScreenSplitToOverlappingPlayers::None"))
	EHazeViewPointBlendSpeed AdjustScreenSplitBlendSpeed = EHazeViewPointBlendSpeed::Normal;

	// Focus settings for a player in volume
	UPROPERTY()
	FHazeFocusTarget PlayerFocus;
	default PlayerFocus.LocalOffset = FVector(0.f, 0.f, 180.f);

	int NumOverlappers = 0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		devEnsure(CameraSettings.Camera != nullptr, "TrackOverlappingPlayersCameraVolume: " + Name + " needs to have a valid camera in settings!");

		OnEntered.AddUFunction(this, n"OnEnteredVolume");
		OnExited.AddUFunction(this, n"OnExitedVolume");
	}

	UFUNCTION()
	void OnEnteredVolume(UHazeCameraUserComponent User)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(User.GetOwner());
		if (Player == nullptr)
			return;

		NumOverlappers++;
		ensure(NumOverlappers <= 2);
		AdjustScreenSplitEnter(Player);

		StartTrackingTranslation(Player, CameraSettings.Camera);
		StartTrackingRotation(Player, CameraSettings.Camera);
	}

	UFUNCTION()
	void OnExitedVolume(UHazeCameraUserComponent User)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(User.GetOwner());
		if (Player == nullptr)
			return;

		NumOverlappers--;
		ensure(NumOverlappers >= 0);
		AdjustScreenSplitExit(Player);

		StopTrackingTranslation(Player, CameraSettings.Camera);
		StopTrackingRotation(Player, CameraSettings.Camera);
	}

	void AdjustScreenSplitEnter(AHazePlayerCharacter Player)
	{
		if (ScreenSplitAdjustment == EAdjustScreenSplitToOverlappingPlayers::None)
			return;

		if (NumOverlappers == 2)
		{
			if (ScreenSplitAdjustment == EAdjustScreenSplitToOverlappingPlayers::Small)
			{
				Player.OtherPlayer.ApplyViewSizeOverride(this, EHazeViewPointSize::Hide, AdjustScreenSplitBlendSpeed);
				Player.ApplyViewSizeOverride(this, EHazeViewPointSize::Fullscreen, AdjustScreenSplitBlendSpeed);
			}
			// Previously overlapping player gets full screen
			else
			{
				Player.OtherPlayer.ApplyViewSizeOverride(this, EHazeViewPointSize::Fullscreen, AdjustScreenSplitBlendSpeed);
				Player.ApplyViewSizeOverride(this, EHazeViewPointSize::Hide, AdjustScreenSplitBlendSpeed);
			}
			return;
		}

		// This is first player to enter
		if (ScreenSplitAdjustment == EAdjustScreenSplitToOverlappingPlayers::Large)
		{
			Player.ApplyViewSizeOverride(this, EHazeViewPointSize::Large, AdjustScreenSplitBlendSpeed);
			Player.OtherPlayer.ApplyViewSizeOverride(this, EHazeViewPointSize::Small, AdjustScreenSplitBlendSpeed);
		}

		// This is first player to enter
		if (ScreenSplitAdjustment == EAdjustScreenSplitToOverlappingPlayers::Small)
		{
			Player.ApplyViewSizeOverride(this, EHazeViewPointSize::Small, AdjustScreenSplitBlendSpeed);
			Player.OtherPlayer.ApplyViewSizeOverride(this, EHazeViewPointSize::Large, AdjustScreenSplitBlendSpeed);
		}
	}

	void AdjustScreenSplitExit(AHazePlayerCharacter Player)
	{
		if (ScreenSplitAdjustment == EAdjustScreenSplitToOverlappingPlayers::None)
			return;

		if (NumOverlappers == 1)
		{
			// We were in full screen, keep split for the remaining player
			if (ScreenSplitAdjustment == EAdjustScreenSplitToOverlappingPlayers::Large)
			{
				Player.OtherPlayer.ApplyViewSizeOverride(this, EHazeViewPointSize::Large, AdjustScreenSplitBlendSpeed);
				Player.ApplyViewSizeOverride(this, EHazeViewPointSize::Small, AdjustScreenSplitBlendSpeed);
				return;
			}
		}

		// No overlappers, or we want normal split on one overlapper
		Player.OtherPlayer.ApplyViewSizeOverride(this, EHazeViewPointSize::Normal, AdjustScreenSplitBlendSpeed);
		Player.ApplyViewSizeOverride(this, EHazeViewPointSize::Normal, AdjustScreenSplitBlendSpeed);
	}

	void StartTrackingTranslation(AHazePlayerCharacter Player, AHazeCameraActor Camera)
	{
		FHazeFocusTarget Focus = PlayerFocus;
		Focus.Actor = Player;

		UCameraKeepInViewComponent KeepInViewComp = UCameraKeepInViewComponent::Get(Camera);
		if (KeepInViewComp != nullptr)
			KeepInViewComp.AddTarget(Focus);

		UCameraSplineFollowerComponent SplineFollowerComp = UCameraSplineFollowerComponent::Get(Camera);
		if (SplineFollowerComp != nullptr)
		{
			FSplineFollowTarget FollowTarget;
			FollowTarget.Target = Focus;
			FollowTarget.Weight = 1.f;
			SplineFollowerComp.AddFollowTarget(FollowTarget, EHazeSelectPlayer::Both);
		}
	}

	void StopTrackingTranslation(AHazePlayerCharacter Player, AHazeCameraActor Camera)
	{
		UCameraKeepInViewComponent KeepInViewComp = UCameraKeepInViewComponent::Get(Camera);
		if (KeepInViewComp != nullptr)
			KeepInViewComp.RemoveTarget(Player);

		UCameraSplineFollowerComponent SplineFollowerComp = UCameraSplineFollowerComponent::Get(Camera);
		if (SplineFollowerComp != nullptr)
			SplineFollowerComp.RemoveFollowTarget(Player, EHazeSelectPlayer::Both);
	}

	void StartTrackingRotation(AHazePlayerCharacter Player, AHazeCameraActor Camera)
	{
		UFocusTrackerComponent FocusTrackerComp = UFocusTrackerComponent::Get(Camera);
		if (FocusTrackerComp != nullptr)
		{
			FFocusTrackerTarget FocusTarget;
			FocusTarget.Focus = PlayerFocus;
			FocusTarget.Focus.Actor = Player;
			FocusTarget.Weight = 1.f;
			FocusTrackerComp.AddFocusTarget(FocusTarget, EHazeSelectPlayer::Both);
		}
	}

	void StopTrackingRotation(AHazePlayerCharacter Player, AHazeCameraActor Camera)
	{
		UFocusTrackerComponent FocusTrackerComp = UFocusTrackerComponent::Get(Camera);
		if (FocusTrackerComp != nullptr)
			FocusTrackerComp.RemoveFocusTarget(Player, EHazeSelectPlayer::Both);
	}
}