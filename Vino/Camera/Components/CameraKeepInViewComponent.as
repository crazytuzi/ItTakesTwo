import Vino.PlayerHealth.PlayerHealthStatics;
import Vino.Camera.Components.CameraUserComponent;

event void FOutOfViewEventSignature(AActor Actor);
event void FReenterViewEventSignature(AActor Actor);

enum EKeepInViewOrientation
{
    Horizontal,
    Vertical
}

enum EKeepinViewPlayerFocus
{
	None, 		// No automatic extra focus targets
	User, 		// User is always added as focus target when activating camera
	OtherPlayer,// The other player is always added as focus target when activating camera
	AllPlayers,	// All players are always added as focus target when activating camera 
}

enum EKeepInViewBlendState
{
	BlendIn,	 	 // Target is blending in (or fully blended in)
	InvalidBlendOut, // Target is blending out due to being invalid 
	ForceBlendOut,	 // Target is blending out due to script, will not blend in due to becoming valid
	AlwaysValid,	 // Target is blending in and will not blend out even if becoming invalid 
}

enum EKeepInViewInvalidBlendOutBehaviour
{
	KeepLocal, 		// Any invalid focus targets will have their focus targets stay in place until valid again. Nice for maintaining framing when a dead player quickly respawns.
	BlendToCenter,	// When invalid, the focus target blends to camera local center using the InvalidBlendOutTime setting.
	Remove,			// When invalid, the focus target will immediately stop being used.
	FollowInvalids,	// Keep following invalid focus targets, e.g. dead players
}

struct FKeepInViewTarget
{
	UPROPERTY()
	FHazeFocusTarget FocusTarget;

	// How completely the focus target is blended in, 0..1
	FHazeAcceleratedFloat BlendFraction;

	// How fast this target blend in/out
	float BlendDuration = 2.f;

	// Current blend state
	EKeepInViewBlendState BlendState = EKeepInViewBlendState::BlendIn;

	FVector LocalLocation = FVector(1000.f, 0.f, 0.f); // This default value will be used if target blends out immediately.
	FVector WorldBlendInOrigin; 
	FVector LocalBlendOutOrigin;
	bool bRemoveAfterBlendOut = false;

	FKeepInViewTarget(FHazeFocusTarget FocusTarget, USceneComponent Owner, AHazePlayerCharacter User, float BlendFraction = 1.f)
	{
		this.FocusTarget = FocusTarget;
		this.BlendFraction.SnapTo(BlendFraction);
		WorldBlendInOrigin = FocusTarget.GetFocusLocation(User);
		LocalLocation = Owner.WorldTransform.InverseTransformPosition(WorldBlendInOrigin);
		LocalBlendOutOrigin = LocalLocation;
	}

	bool IsBlendingOut() const
	{
		return (BlendState == EKeepInViewBlendState::InvalidBlendOut) || (BlendState == EKeepInViewBlendState::ForceBlendOut);
	}
}

class UCameraKeepInViewComponent : UHazeCameraParentComponent
{
	// Should any player be added as focus targets automatically when activating camera?
	UPROPERTY()
	EKeepinViewPlayerFocus PlayerFocus = EKeepinViewPlayerFocus::User;

    // Any player focii will use these offsets and other properties. Note that the 'Actor' property will be replaced by respective player.
    UPROPERTY(meta = (EditCondition="PlayerFocus != EKeepinViewPlayerFocus::None"))
    FHazeFocusTarget PlayerFocusProperties;

    // If valid, component will always be adjusted to keep this target in view.
    UPROPERTY(AdvancedDisplay)
    FHazeFocusTarget PrimaryTarget;

    // The targets we want to keep in view, if possible due to fov and distance constraints
    UPROPERTY()
    TArray<FHazeFocusTarget> FocusTargets;

    // Camera will never approach closer than this to primary (or nearest focus target if there is no primary)
    UPROPERTY(Category = "Camera Settings")
    float MinDistance = 1000.f;

    FRotator LookOffset = FRotator::ZeroRotator;

    // This buffer distance is always applied
    UPROPERTY(Category = "Camera Settings")
    float BufferDistance = 300.f;

    // Camera will never move further away than this from primary (or nearest focus target if there is no primary)
    UPROPERTY(Category = "Camera Settings")
    float MaxDistance = 3000.f;

    // How fast camera will adjust location
    UPROPERTY(Category = "Camera Settings")
    float AccelerationDuration = 2.f;    
    FHazeAcceleratedFloat CurrentAccelerationDuration;

	// How fast a previous invalid target blends in (e.g. if we use EKeepInViewInvalidBlendOutBehaviour::KeepLocal or BlendToCenter)
	UPROPERTY(Category = "Camera Settings")
	float RespawnBlendInDuration = 5.f;

	// How fast a previously valid target blends out (e.g. if we use EKeepInViewInvalidBlendOutBehaviour::BlendToCenter)
	UPROPERTY(Category = "Camera Settings")
	float InvalidBlendOutDuration = 5.f;

    // This will be broadcast whenever a focus target is forced outside of view, due to MaxDistance etc.
   	UPROPERTY(Category = "Camera events")
	FOutOfViewEventSignature OnOutOfView;

    // Tbis is broadcast  whenever a focus target which was outside of view comes back within view. It does not trigger when starting within view.
   	UPROPERTY(Category = "Camera events")
    FReenterViewEventSignature OnReEnterView;

    // How much the camera is currently allowed to move towards the target value. Normally (1,1,1), if (0,0,0) it's locked in all axes, if (1,1,0) it's locked upwards/downwards.
    UPROPERTY(Category = "Camera Settings", BlueprintReadOnly, EditAnywhere)
    FVector AxisFreedomFactor = FVector::OneVector;

	// If set, the camera will use this focus target as it's center to lock axes relative to. If not set, camera will always be locked relative to current location.
	UPROPERTY(Category = "Camera Settings", BlueprintReadOnly, EditAnywhere)
	FHazeFocusTarget AxisFreedomCenter;

	// If > 0, camera will try to start with an initial velocity matching that of it's focus targets. This means it will also try to start at an appropriate lagged position. Use this value to tweak how far behind it will lag.
	UPROPERTY(Category = "Camera Settings", BlueprintReadOnly, EditAnywhere)
	float MatchInitialVelocityFactor = 0.f;

	// If true, all settings on this camera will snap when camera is activated. If false, they blend in over camera blend duration.
    UPROPERTY(Category = "Camera Settings")
    bool bSnapDefaultSettingsOnActivate = true;    

	// If set, camera will not be able to leave this volume. Note that volume should be convex, if it's concave you can "trap" the camera in a nook.
	UPROPERTY(BlueprintReadOnly, EditAnywhere)
	AVolume ConstraintVolume = nullptr;

    UPROPERTY(Transient, BlueprintHidden, NotEditable)
    TArray<FKeepInViewTarget> AllFocusTargets;

    FHazeAcceleratedVector AcceleratedLocation;
    AHazePlayerCharacter PlayerUser;
    UHazeCameraUserComponent User;
    TSet<AActor> ActorsOutOfView;

	bool bFollowBothPlayers = false;

	UPROPERTY()
	EKeepInViewInvalidBlendOutBehaviour InvalidBlendOutBehaviour = EKeepInViewInvalidBlendOutBehaviour::KeepLocal;

    UFUNCTION(BlueprintOverride)
	void OnCameraActivated(UHazeCameraUserComponent _User, EHazeCameraState PreviousState)
	{
        ResetCurrentAccelerationDuration();
        
        User = _User;
        PlayerUser = Cast<AHazePlayerCharacter>(User.GetOwner());
        ActorsOutOfView.Empty();
        LookOffset = RelativeRotation;

		if (AllFocusTargets.Num() == 0)
			InitializeFocusTargets();

		// Apply default settings so we'll blend out of them correctly. 
		FHazeCameraKeepInViewSettings Settings;
		GetDefaultSettings(Settings);

		float BlendTime = (Camera.LastActivationBlend.BlendTime >= 0.f) ? Camera.LastActivationBlend.BlendTime : 2.f;

		if (PreviousState == EHazeCameraState::Inactive)
		{
			// Snap to target
			if (bSnapDefaultSettingsOnActivate)
				BlendTime = 0.f; 
			PlayerUser.ApplyCameraKeepInViewSettings(Settings, CameraBlend::Normal(BlendTime), this, EHazeCameraPriority::Minimum);
			Snap();
		}
		else
		{
			// Apply settings using last activation blend time
			PlayerUser.ApplyCameraKeepInViewSettings(Settings, CameraBlend::Normal(BlendTime), this, EHazeCameraPriority::Minimum);
		}
    }

    UFUNCTION(BlueprintOverride)
	void OnCameraFinishedBlendingOut(UHazeCameraUserComponent _User, EHazeCameraState PreviousState)
	{
		PlayerUser.ClearCameraSettingsByInstigator(this);
	}

	private void AddPlayerFocusTarget(AHazePlayerCharacter Player)
	{
 		if (ContainsTargetActor(Player))
			return;
		if (PrimaryTarget.Actor == Player)
			return;

		FHazeFocusTarget PlayerFocusTarget = PlayerFocusProperties;
		PlayerFocusTarget.Actor = Player;
		FocusTargets.Add(PlayerFocusTarget);
	}

	FVector GetLocalCenterLocation(const FHazeCameraKeepInViewSettings& Settings)
	{
		return FVector(Settings.MinDistance, 0.f, 0.f);
	}

    bool ContainsTargetActor(AHazeActor Actor)
    {
		if (PrimaryTarget.Actor == Actor)
			return true;

        for (const FHazeFocusTarget& FocusTarget : FocusTargets)
        {
            if (FocusTarget.Actor == Actor)
                return true;
        }
        return false;
    }

	void InitializeFocusTargets()
	{
		AllFocusTargets.Empty(FocusTargets.Num() + 2);

		// Add players as focus targets based on the player focus property
		switch (PlayerFocus)
		{
			case EKeepinViewPlayerFocus::None:
				break;
			case EKeepinViewPlayerFocus::User:
				AddPlayerFocusTarget(PlayerUser);
				break;
			case EKeepinViewPlayerFocus::OtherPlayer:
				AddPlayerFocusTarget(PlayerUser.OtherPlayer);
				break;
			case EKeepinViewPlayerFocus::AllPlayers: 
			{
				TArray<AHazePlayerCharacter> Players = Game::GetPlayers();
				for (AHazePlayerCharacter Player : Players)
					AddPlayerFocusTarget(Player);
				break;
			}
		}

		// Add all normal focus targets
		for (const FHazeFocusTarget& FocusTarget : FocusTargets)
		{
			if (FocusTarget.IsValid())
				AllFocusTargets.Add(FKeepInViewTarget(FocusTarget, this, PlayerUser));			
		}

		// Add primary target
		SetPrimaryTargetInternal(PrimaryTarget);

        bFollowBothPlayers = IsFollowingBothPlayers();
	}

	bool IsFollowingBothPlayers()
	{
		// Are we following both players?
		if (PlayerFocus == EKeepinViewPlayerFocus::AllPlayers)
			return true;
		// Make sure we find two players
		int NumPlayersToFind = Game::GetPlayers().Num();
		for (FKeepInViewTarget Target : AllFocusTargets)
		{
			AActor Actor = Target.FocusTarget.Actor;
			if (Target.FocusTarget.Component != nullptr)
				Actor = Target.FocusTarget.Component.Owner;

			if (Actor != nullptr && Actor.IsA(AHazePlayerCharacter::StaticClass()))
			{
				NumPlayersToFind--;
				if (NumPlayersToFind == 0)
					return true;
			}
		}
		return false;
	}

	void GetDefaultSettings(FHazeCameraKeepInViewSettings& OutSettings)
	{
        // Own settings are used as defaults (only used if we have no user, as these are added at min prio when activated as well)
        OutSettings.bUseAccelerationDuration = true;
        OutSettings.AccelerationDuration = AccelerationDuration;
        OutSettings.bUseMinDistance = true;        
        OutSettings.MinDistance = MinDistance;
        OutSettings.bUseMaxDistance = true;        
        OutSettings.MaxDistance = MaxDistance;
        OutSettings.bUseBufferDistance = true;        
        OutSettings.BufferDistance = BufferDistance;
        OutSettings.bUseLookOffset = true;        
        OutSettings.LookOffset = LookOffset;	
        OutSettings.bUseRespawnBlendInDuration = true;        
		OutSettings.RespawnBlendInDuration = RespawnBlendInDuration;
        OutSettings.bUseInvalidBlendOutDuration = true;        
		OutSettings.InvalidBlendOutDuration = InvalidBlendOutDuration;
    }

	void GetSettings(FHazeCameraKeepInViewSettings& OutSettings)
	{
        // Own settings are used as defaults (only used on activation or if we have no user, as these are added at min prio when activated as well)
        GetDefaultSettings(OutSettings);

		// Override with user settings
        if (User != nullptr)
        {
            FHazeCameraKeepInViewSettings UserSettings;
            User.GetCameraKeepInViewSettings(UserSettings);
            OutSettings.Override(UserSettings);
        }
	}

	float GetViewAspectRatio()
	{
		if (PlayerUser == nullptr)
			return (8.f / 9.f);

        FVector2D Resolution = SceneView::GetPlayerViewResolution(PlayerUser);
		if (Resolution.ContainsNaN())
			return NAN_flt;

		return Resolution.X / FMath::Max(1.f, Resolution.Y);
	}

	void GetFOVs(float FOV, float AspectRatio, float& VerticalFOV, float& HorizontalFOV)
	{
        VerticalFOV = FMath::Clamp(FOV, 5.f, 89.f);
        HorizontalFOV = FMath::Clamp(FMath::RadiansToDegrees(2 * FMath::Atan(FMath::Tan(FMath::DegreesToRadians(FOV * 0.5)) * AspectRatio)), 5.f, 179.f);
	}

	FVector ProjectToView(const FVector& LocalLocation, const FHazeCameraKeepInViewSettings& Settings, float FOV)
	{
		FVector ProjectedLoc = LocalLocation;
		float EffectiveMinDistance = FMath::Max(Settings.MinDistance, Settings.BufferDistance);
		ProjectedLoc.X = FMath::Clamp(LocalLocation.X, EffectiveMinDistance, Settings.MaxDistance);
		
		// Get FOVs
		float AspectRatio = GetViewAspectRatio();
		if (FMath::IsNaN(AspectRatio))
			return ProjectedLoc;
	    float VerticalFOV = 70.f;
        float HorizontalFOV = 70.f;
		GetFOVs(FOV, AspectRatio, VerticalFOV, HorizontalFOV);

		// Clamp location Y and Z to within respective FOV from the point (EffectiveMinDistance, 0, 0)
		float FOVForwardOffset = (ProjectedLoc.X - EffectiveMinDistance);
		float HorizontalMax = FMath::Tan(FMath::DegreesToRadians(HorizontalFOV * 0.5f)) * FOVForwardOffset;
		ProjectedLoc.Y = FMath::Clamp(ProjectedLoc.Y, -HorizontalMax, HorizontalMax);
		float VerticalMax = FMath::Tan(FMath::DegreesToRadians(VerticalFOV * 0.5f)) * FOVForwardOffset;
		ProjectedLoc.Z = FMath::Clamp(ProjectedLoc.Z, -VerticalMax, VerticalMax);

		return ProjectedLoc;
	}

    private FVector GetTargetLocation(const FHazeCameraKeepInViewSettings& Settings, float FOV)
    {
#if TEST
		// This should already have returned true for this function to have been called.
		ensure(HasActiveFocusTargets());
#endif
		float AspectRatio = GetViewAspectRatio();
		if (FMath::IsNaN(AspectRatio))
			return GetWorldLocation();

	    float VerticalFOV = 70.f;
        float HorizontalFOV = 70.f;
		GetFOVs(FOV, AspectRatio, VerticalFOV, HorizontalFOV);

        TArray<FVector> FocusLocations;
        for (const FKeepInViewTarget& Target : AllFocusTargets)
        {
			if ((InvalidBlendOutBehaviour == EKeepInViewInvalidBlendOutBehaviour::Remove) && 
				(Target.BlendState == EKeepInViewBlendState::InvalidBlendOut))
				continue; // We skip any invalid targets. 

			FocusLocations.Add(Target.LocalLocation);
        }

        // Find the horizontal and vertical intersections of fov lines through rightmost/leftmost and highest/lowest focus points.
        // This is where camera needs to be to show all focii
        FVector2D HorizontalIntersection = GetIdealCameraLocation(FocusLocations, HorizontalFOV, EKeepInViewOrientation::Horizontal);
        FVector2D VerticalIntersection = GetIdealCameraLocation(FocusLocations, VerticalFOV, EKeepInViewOrientation::Vertical);

        // Combine the horizontal and vertical intersections to get 3D intersection in camera space 
        // Note that we want the location furthest back, i.e. lowest X
        FVector Intersection;
        Intersection.X = FMath::Min(HorizontalIntersection.X, VerticalIntersection.X);
        Intersection.Y = HorizontalIntersection.Y;
        Intersection.Z = VerticalIntersection.Y;

        // Find reference distance for min/max clamps
        FTransform CameraTransform = GetWorldTransform();
		float ClampedBufferDistance = FMath::Min(Settings.BufferDistance, Settings.MaxDistance); // Buffer distance is not meaningful if greater than max
        float MinWithBuffer = Settings.MinDistance - ClampedBufferDistance;
        float MaxWithBuffer = Settings.MaxDistance - ClampedBufferDistance;
        float FocusDistance = Math::BigNumber;
        if (PrimaryTarget.IsValid())
        {
            // Always use distance to primary 
            FVector PrimaryFocusLoc = CameraTransform.InverseTransformPosition(PrimaryTarget.GetFocusLocation(PlayerUser));
            FocusDistance = PrimaryFocusLoc.X - Intersection.X;

            // Make sure primary target is within view even when max distance clamp is applied
            if (FocusDistance > MaxWithBuffer)
            {
                FVector MaxDistanceClampedIntersection = Intersection;
                MaxDistanceClampedIntersection.X -= MaxWithBuffer - FocusDistance; 
                Intersection.Y = KeepLocationWithinView(PrimaryFocusLoc, MaxDistanceClampedIntersection, HorizontalFOV, EKeepInViewOrientation::Horizontal);
                Intersection.Z = KeepLocationWithinView(PrimaryFocusLoc, MaxDistanceClampedIntersection, VerticalFOV, EKeepInViewOrientation::Vertical);
            }
        }
        else
        {
            // No primary, use the closest focus point
            for (FVector FocusLoc : FocusLocations)
            {
                float Distance = FocusLoc.X - Intersection.X;
                FocusDistance = FMath::Min(FocusDistance, Distance); 
            }
        }

        // Clamp to min/max distances (including buffer)
        if (FocusDistance > MaxWithBuffer)
            Intersection.X -= MaxWithBuffer - FocusDistance;
        else if (FocusDistance < MinWithBuffer)
            Intersection.X -= MinWithBuffer - FocusDistance;

        // Apply buffer distance
        Intersection.X -= ClampedBufferDistance;

        CheckOutOfView(Intersection, CameraTransform, AllFocusTargets, HorizontalFOV, VerticalFOV);

        if (AxisFreedomFactor != FVector::OneVector)
        {
			FVector LocalConstrainCenter = FVector::ZeroVector;
			if (AxisFreedomCenter.IsValid())
				LocalConstrainCenter = CameraTransform.InverseTransformPosition(AxisFreedomCenter.GetFocusLocation(PlayerUser));
            Intersection.X = FMath::Lerp(LocalConstrainCenter.X, Intersection.X, AxisFreedomFactor.X);
            Intersection.Y = FMath::Lerp(LocalConstrainCenter.Y, Intersection.Y, AxisFreedomFactor.Y);
            Intersection.Z = FMath::Lerp(LocalConstrainCenter.Z, Intersection.Z, AxisFreedomFactor.Z);
        }

		FVector TargetWorldLocation = CameraTransform.TransformPosition(Intersection);
		if (ConstraintVolume != nullptr)
		{
			// Keep camera within volume
			FVector ToTarget = (TargetWorldLocation - AcceleratedLocation.Value);
			if (!ToTarget.IsNearlyZero())
			{
				TargetWorldLocation = ConstraintVolume.FindClosestPoint(TargetWorldLocation);
				if (TargetWorldLocation == FVector(BIG_NUMBER))
					TargetWorldLocation = AcceleratedLocation.Value; // Failed to find closest location within volume
			}
		}

        return TargetWorldLocation;
    }

	float GetSettingsFOV()
	{
		FHazeCameraSettings Settings;
		if ((User != nullptr) && User.GetCameraSettings(Settings))
			return Settings.FOV;
		return Camera.Settings.FOV;
	}

    UFUNCTION(BlueprintOverride)
    void Update(float DeltaTime)
    {
        if (PlayerUser == nullptr)
            return;

		FHazeCameraKeepInViewSettings Settings;
        GetSettings(Settings);
		float FOV = GetSettingsFOV();

        SetRelativeRotation(Settings.LookOffset);
        CurrentAccelerationDuration.AccelerateTo(Settings.AccelerationDuration, CurrentAccelerationDuration.Value, DeltaTime);
		UpdateFocusTargetBlend(DeltaTime, Settings, FOV);
		if (HasActiveFocusTargets())
		{
			// Accelerate to target location
			FVector TargetWorldIntersection = GetTargetLocation(Settings, FOV);
			AcceleratedLocation.AccelerateTo(TargetWorldIntersection, CurrentAccelerationDuration.Value, DeltaTime);
		}
		else
		{	
			// No active targets, slide to a stop
			float Dampening = 5.f / FMath::Max(0.1f, CurrentAccelerationDuration.Value);
			AcceleratedLocation.Velocity -= AcceleratedLocation.Velocity * FMath::Min(1.f, Dampening * DeltaTime);
			AcceleratedLocation.Value += AcceleratedLocation.Velocity * DeltaTime;
		}
		SetWorldLocation(AcceleratedLocation.Value);
    }

	bool HasActiveFocusTargets()
	{
		// We need at least one non-blending out target
		for (const FKeepInViewTarget& Target : AllFocusTargets)
		{
			if (!Target.IsBlendingOut())
				return true;
		}
		return false;
	}

	void CleanDestroyedAndBlendedOutTargets()
	{
		// Remove any focus targets which have been destroyed
		for (int i = AllFocusTargets.Num() - 1; i >= 0; i--)
		{
			FKeepInViewTarget& Target = AllFocusTargets[i];
			if (!Target.FocusTarget.IsValid()
				|| (Target.bRemoveAfterBlendOut && Target.IsBlendingOut() && Target.BlendFraction.Value <= KINDA_SMALL_NUMBER))
			{
			 	AllFocusTargets.RemoveAtSwap(i);
			}
		}
	}

	void SnapFocusTargets()
	{
		CleanDestroyedAndBlendedOutTargets();
		FTransform WorldToLocal = WorldTransform.Inverse();
		for (FKeepInViewTarget& Target : AllFocusTargets)
		{
			FVector FocusLoc = Target.FocusTarget.GetFocusLocation(PlayerUser);
			Target.LocalLocation = WorldToLocal.TransformPosition(FocusLoc); 
			switch (Target.BlendState)
			{
				case EKeepInViewBlendState::BlendIn:
				{
					Target.BlendFraction.SnapTo(1.f);
					Target.WorldBlendInOrigin = FocusLoc;
					break;
				}
				case EKeepInViewBlendState::InvalidBlendOut:
				{
					Target.BlendFraction.SnapTo(0.f);
					Target.LocalBlendOutOrigin = Target.LocalLocation;
					break;
				}
			}
		}	
	}

	void UpdateFocusTargetBlend(float DeltaTime, const FHazeCameraKeepInViewSettings& Settings, float FOV)
	{
		CleanDestroyedAndBlendedOutTargets();

		// Update remaining targets 
		FTransform LocalToWorld = WorldTransform;
		FTransform WorldToLocal = LocalToWorld.Inverse();
		FVector BlendCenter = FVector(Settings.MinDistance, 0.f, 0.f);
		for (FKeepInViewTarget& Target : AllFocusTargets)
		{	
			// Update blend state
			bool bIsValid = IsValidFocusTarget(Target);
			switch (Target.BlendState)
			{
				case EKeepInViewBlendState::BlendIn:
				{
					if (!bIsValid)
					{
						// Just became invalid, blend out
						Target.BlendState = EKeepInViewBlendState::InvalidBlendOut;
						Target.BlendDuration = Settings.InvalidBlendOutDuration;
						Target.LocalBlendOutOrigin = Target.LocalLocation;
						Target.BlendFraction.SnapTo(1.f);
					}
					break;
				}
				case EKeepInViewBlendState::InvalidBlendOut:
				{
					if (bIsValid)
					{
						// Just became valid, blend in
						Target.BlendState = EKeepInViewBlendState::BlendIn;
						Target.BlendDuration = Settings.RespawnBlendInDuration;
						Target.WorldBlendInOrigin = LocalToWorld.TransformPosition(Target.LocalLocation);
						Target.BlendFraction.SnapTo(0.f);
					}
					break;
				}
			}

			if (Target.IsBlendingOut())
			{
				if ((InvalidBlendOutBehaviour == EKeepInViewInvalidBlendOutBehaviour::KeepLocal) &&
					(Target.BlendState == EKeepInViewBlendState::InvalidBlendOut))
				{
					// Maintain local position while blended out due to being invalid
					// We snap location to edge of view and to within max/min distance 
					// if outside to make sure view won't drift due to this focus target
					Target.LocalLocation = ProjectToView(Target.LocalLocation, Settings, FOV);
				}
				else
				{
					// Blend local position towards camera center
					Target.BlendFraction.AccelerateTo(0.f, Target.BlendDuration, DeltaTime);
					Target.LocalLocation = FMath::Lerp(GetLocalCenterLocation(Settings), Target.LocalBlendOutOrigin, Target.BlendFraction.Value);
					Target.LocalLocation = ProjectToView(Target.LocalLocation, Settings, FOV);
				}
			}
			else // Blending in
			{
				Target.BlendFraction.AccelerateTo(1.f, Target.BlendDuration, DeltaTime);
				FVector TargetLoc = WorldToLocal.TransformPosition(Target.FocusTarget.GetFocusLocation(PlayerUser));
				Target.LocalLocation = FMath::Lerp(WorldToLocal.TransformPosition(Target.WorldBlendInOrigin), TargetLoc, Target.BlendFraction.Value);
			}
#if EDITOR
			//bHazeEditorOnlyDebugBool = true;
			if (bHazeEditorOnlyDebugBool && (!SceneView::IsFullScreen() || (SceneView::GetFullScreenPlayer() == PlayerUser)))
			{
				if (Target.IsBlendingOut())
				{
					System::DrawDebugLine(LocalToWorld.TransformPosition(Target.LocalLocation), Target.FocusTarget.GetFocusLocation(PlayerUser), FLinearColor::Gray, 0.f, 1.f);			
					System::DrawDebugPoint(LocalToWorld.TransformPosition(Target.LocalLocation), 10.f, FLinearColor::Red);
				}
				else
				{
					System::DrawDebugLine(Target.WorldBlendInOrigin, Target.FocusTarget.GetFocusLocation(PlayerUser), FLinearColor::Yellow, 0.f, 1.f);			
					System::DrawDebugPoint(LocalToWorld.TransformPosition(Target.LocalLocation), 10.f, FLinearColor::Green);
				}
			}
#endif
		}
	}

    UFUNCTION(BlueprintOverride)
    void Snap()
    {
        if (PlayerUser == nullptr)
            return;

		InitializeFocusTargets();

		// Any settings asset of the camera component will be applied using the blend time of the camera activation
		// which means we might get blended settings. Snap the keep in view settings only to compensate.
		// Note: this is only needed since we use centralized settings, if we had per camera settings we could always snap those.
		UHazeCameraKeepInViewSettingsDataAsset KeepInViewAsset = Cast<UHazeCameraKeepInViewSettingsDataAsset>(Camera.SettingsAsset);
		if ((KeepInViewAsset != nullptr) && (KeepInViewAsset.KeepInViewSettings.IsUsed()))
			PlayerUser.ApplyCameraKeepInViewSettings(KeepInViewAsset.KeepInViewSettings, CameraBlend::Normal(0.f), this, Camera.SettingsPriority);	

        FHazeCameraKeepInViewSettings Settings;
        GetSettings(Settings);
        SetRelativeRotation(Settings.LookOffset);
		float FOV = GetSettingsFOV();
		SnapFocusTargets(); // In case camera has been moved by look offset or outside factors
		if (HasActiveFocusTargets())
        	AcceleratedLocation.SnapTo(GetTargetLocation(Settings, FOV));
		else
			AcceleratedLocation.SnapTo(GetWorldLocation());

		CurrentAccelerationDuration.SnapTo(Settings.AccelerationDuration);

		if (MatchInitialVelocityFactor > 0.f)
		{
			// Try to match accelerated location and velocity with average focus velocity
			FVector FocusVelocity = FVector::ZeroVector;
			for (FKeepInViewTarget Target : AllFocusTargets)
			{
				if (Target.FocusTarget.Component != nullptr)
					FocusVelocity += Target.FocusTarget.Component.ComponentVelocity;	
				else if (Target.FocusTarget.Actor != nullptr)
				{
					AHazeActor HazeActor = Cast<AHazeActor>(Target.FocusTarget.Actor);
					if (HazeActor != nullptr)
						FocusVelocity += HazeActor.GetActualVelocity();
					else 
						FocusVelocity += Target.FocusTarget.Actor.ActorVelocity;
				}
			}
			FocusVelocity /= AllFocusTargets.Num();
			
			// Lag behind at start, but with appropriate velocity
			AcceleratedLocation.Value -= (FocusVelocity * (Settings.AccelerationDuration * 0.5f * MatchInitialVelocityFactor));			
			AcceleratedLocation.Velocity = FocusVelocity * MatchInitialVelocityFactor;
		}

	    Update(0.f);
    }

    FVector2D GetVectorIn2DOrientation(FVector Vector, EKeepInViewOrientation Orientation)
    {
        if (Orientation == EKeepInViewOrientation::Horizontal)
            return FVector2D(Vector.X, Vector.Y);
        else
            return FVector2D(Vector.X, Vector.Z);
    } 

    FVector2D GetIdealCameraLocation(const TArray<FVector>& FocusLocations, float FieldOfView, EKeepInViewOrientation Orientation)
    {
        // Find highest(rightmost) and lowest(leftmost) focus locations. Note that these may be the same location.
        FVector2D LowestLocation = GetVectorIn2DOrientation(FocusLocations[0], Orientation);
        FVector2D HighestLocation = GetVectorIn2DOrientation(FocusLocations[0], Orientation);

        float HalfFOV = FieldOfView * 0.5f;
        float SinHalfFOV = 0.f;
        float CosHalfFOV = 1.f;
        FMath::SinCos(SinHalfFOV, CosHalfFOV, FMath::DegreesToRadians(HalfFOV));

        FVector2D LowOrthogonal = FVector2D(SinHalfFOV, -CosHalfFOV);
        FVector2D HighOrthogonal = FVector2D(SinHalfFOV, CosHalfFOV);
        for (int32 i = 1; i < FocusLocations.Num(); i++)
        {
            FVector2D FocusLoc2D = GetVectorIn2DOrientation(FocusLocations[i], Orientation);   
                     
            FVector2D ToHighestLocation = HighestLocation - FocusLoc2D;                        
            if (ToHighestLocation.DotProduct(LowOrthogonal) > 0)                
                HighestLocation = FocusLoc2D;
       
            FVector2D ToLowestLocation = LowestLocation - FocusLoc2D;
            if (ToLowestLocation.DotProduct(HighOrthogonal) > 0)
                LowestLocation = FocusLoc2D;
        }

        // Find intersection between lines from highest location in high fov direction and lowest with low fov direction.
        FVector2D LowFOV = FVector2D(CosHalfFOV, -SinHalfFOV);
        FVector2D HighFOV = FVector2D(CosHalfFOV, SinHalfFOV);
        float HighDistanceToIntersection = GetIntersectionDistance(HighestLocation, HighFOV, LowestLocation, LowFOV);
        return HighestLocation - HighFOV * HighDistanceToIntersection; // Move backwards along FOV direction since it's away from intersection
    }

    // Calculate what 2D Y value is needed to keep given location within view when X is fixed.
    float KeepLocationWithinView(const FVector& KeepInViewLoc, const FVector& ViewLocation, float FieldOfView, EKeepInViewOrientation Orientation)
    {
        FVector2D KeepInViewLoc2D = GetVectorIn2DOrientation(KeepInViewLoc, Orientation);
        FVector2D ViewLoc2D = GetVectorIn2DOrientation(ViewLocation, Orientation);
        
        float HalfFOV = FieldOfView * 0.5f;
        float SinHalfFOV = 0.f;
        float CosHalfFOV = 1.f;
        FMath::SinCos(SinHalfFOV, CosHalfFOV, FMath::DegreesToRadians(HalfFOV));
        FVector2D LowFOV = FVector2D(CosHalfFOV, -SinHalfFOV);
        FVector2D HighFOV = FVector2D(CosHalfFOV, SinHalfFOV);
        FVector2D SideDir = FVector2D(0.f, -1.f); // Since FOV directions are away from intersection
        
        // Find intersections between lines in FOV direction starting at location to keep in view and the 
        // line fixed X (0,1) direction line through the view location
        float LowFOVIntersectionDistance = GetIntersectionDistance(ViewLoc2D, SideDir, KeepInViewLoc2D, LowFOV); 
        float HighFOVIntersectionDistance = GetIntersectionDistance(ViewLoc2D, SideDir, KeepInViewLoc2D, HighFOV); 

        // If lines intersect at either side of view location, it is already within view and can be returned as is.
        if (FMath::Sign(LowFOVIntersectionDistance) != FMath::Sign(HighFOVIntersectionDistance))
            return ViewLoc2D.Y;

        // If lines intersect on the low side of the view location, low fov intersection will be closest
        if (LowFOVIntersectionDistance < 0)
            return ViewLoc2D.Y + LowFOVIntersectionDistance;

        // Lines intersect on the high side of the view location, high fov intersection will be closest
        return ViewLoc2D.Y + HighFOVIntersectionDistance;  
    }

    // Find distance (can be negative) from start to intersection by other line starting at given locations with given directions.
    // Note that this assumes the directions are normalized and non-parallell 
    float GetIntersectionDistance(const FVector2D& Start, const FVector2D& Dir, const FVector2D& OtherStart, const FVector2D& OtherDir)
    {
        return (HazeCross(Start, OtherDir) - HazeCross(OtherStart, OtherDir)) / HazeCross(Dir, OtherDir);
    }

    float HazeCross(const FVector2D& A, const FVector2D& B)
    {
        return (A.X * B.Y) - (A.Y * B.X);
    } 

	bool IsValidFocusTarget(FKeepInViewTarget Target)
	{
		if (!Target.FocusTarget.IsValid())
			return false;

		if (InvalidBlendOutBehaviour == EKeepInViewInvalidBlendOutBehaviour::FollowInvalids)
			return true; // Anything is valid

		if (Target.FocusTarget.Actor == PrimaryTarget.Actor)
			return true; // Primary is always valid

		if (Target.BlendState == EKeepInViewBlendState::AlwaysValid)
			return true;

		AHazePlayerCharacter FocusPlayer = Cast<AHazePlayerCharacter>(Target.FocusTarget.Actor);
		if (FocusPlayer != nullptr && IsPlayerDead(FocusPlayer))
		{
			// Dead players are only valid if this is the only player we follow
			return !bFollowBothPlayers;
		}
		
		return true;
	}

    void CheckOutOfView(FVector LocalView, const FTransform& ViewTransform, const TArray<FKeepInViewTarget>& Targets, float HorizontalFOV, float VerticalFOV)
    {
        if (!OnOutOfView.IsBound() && !OnReEnterView.IsBound())
            return;

        FVector2D Fwd = FVector2D(1.f, 0.f);
        float CosHalfHorizontalFOV = FMath::Cos(FMath::DegreesToRadians(HorizontalFOV * 0.5f));
        float CosHalfVerticalFOV = FMath::Cos(FMath::DegreesToRadians(VerticalFOV * 0.5f));

        for (const FKeepInViewTarget& Target : Targets)
        {
            if (!Target.FocusTarget.IsValid())
                continue;
        
            AActor FocusActor = Target.FocusTarget.Actor;
            if (FocusActor == nullptr)
                FocusActor = Target.FocusTarget.Component.GetOwner();

            if (FocusActor != nullptr)
            {
                FVector FocusLocation = ViewTransform.InverseTransformPosition(Target.FocusTarget.GetFocusLocation(PlayerUser));
                FVector ToFocus = FocusLocation - LocalView;
                FVector2D ToFocusDirHorizontal = FVector2D(ToFocus.X, ToFocus.Y).GetSafeNormal();
                FVector2D ToFocusDirVertical = FVector2D(ToFocus.X, ToFocus.Z).GetSafeNormal();
                if ((ToFocusDirHorizontal.DotProduct(Fwd) < CosHalfHorizontalFOV) ||
                    (ToFocusDirVertical.DotProduct(Fwd) < CosHalfVerticalFOV))
                {
                    // Outside of view
                    if (!ActorsOutOfView.Contains(FocusActor))
                    {
                        ActorsOutOfView.Add(FocusActor);
                        OnOutOfView.Broadcast(FocusActor);
                    }
                }                        
                else 
                {
                    // Inside view
                    if (ActorsOutOfView.Contains(FocusActor))
                    {
                        ActorsOutOfView.Remove(FocusActor);
                        OnReEnterView.Broadcast(FocusActor);
                    }
                }
            }
        }		
    }

    TArray<UCameraKeepInViewComponent> GetAllKeepInViewCameras()
    {
        // Since I haven't fixed property propagation from camera root component yet, this'll have to suffice
        TArray<UCameraKeepInViewComponent> AllKeepInViews;
        if (GetOwner() != nullptr)
        {
            TArray<UActorComponent> Comps = GetOwner().GetComponentsByClass(UCameraKeepInViewComponent::StaticClass());
            for (UActorComponent Comp : Comps)
            {
                UCameraKeepInViewComponent KeepInViewComp = Cast<UCameraKeepInViewComponent>(Comp);
                if (KeepInViewComp != nullptr)
                    AllKeepInViews.Add(KeepInViewComp); 
            }
        }
        else
        {
            AllKeepInViews.Add(this);
        }
        return AllKeepInViews;
    }

    UFUNCTION()
    void AddTarget(FHazeFocusTarget Target, EHazeSelectPlayer AffectedPlayer = EHazeSelectPlayer::Both)
    {
		if (AffectedPlayer == EHazeSelectPlayer::None)
			return;

        TArray<UCameraKeepInViewComponent> KeepInViews = GetAllKeepInViewCameras();
        for (UCameraKeepInViewComponent KeepInView : KeepInViews)
        {
			if ((KeepInView != nullptr) && (KeepInView.IsUsedByPlayer(AffectedPlayer)))
				KeepInView.AddTargetInternal(Target);
        }
    }

	void AddTargetInternal(FHazeFocusTarget Target)
	{
		// Only allow one focus target per actor/component
		for (int i = FocusTargets.Num() - 1; i >= 0; i--)
		{
			if ((FocusTargets[i].Actor == Target.Actor) && (FocusTargets[i].Component == Target.Component))
				FocusTargets.RemoveAtSwap(i);
		}
		FocusTargets.Add(Target);
		
		if ((Target.Actor == PrimaryTarget.Actor) && (Target.Component == PrimaryTarget.Component))
		{
			// Change primary target in case we've updated offsets
			SetPrimaryTargetInternal(Target);
			return;			
		}		

		for (FKeepInViewTarget& PrevTarget : AllFocusTargets)
		{
			if ((PrevTarget.FocusTarget.Actor == Target.Actor) && (PrevTarget.FocusTarget.Component == Target.Component))
			{
				// Replace existing target, but maintain blend 
				PrevTarget.FocusTarget = Target;
				return;
			}
		} 

		// Brand new target
		AllFocusTargets.Add(FKeepInViewTarget(Target, this, PlayerUser));
	}

    UFUNCTION()
    void BlendInTarget(FHazeFocusTarget Target, float BlendTime, EHazeSelectPlayer AffectedPlayer = EHazeSelectPlayer::Both, bool bBlendInEvenIfInvalid = false)
    {
		if (AffectedPlayer == EHazeSelectPlayer::None)
			return;

        TArray<UCameraKeepInViewComponent> KeepInViews = GetAllKeepInViewCameras();
        for (UCameraKeepInViewComponent KeepInView : KeepInViews)
        {
			if ((KeepInView != nullptr) && (KeepInView.IsUsedByPlayer(AffectedPlayer)))
				KeepInView.BlendInTargetInternal(Target, BlendTime, bBlendInEvenIfInvalid);
        }
    }

	private void BlendInTargetInternal(FHazeFocusTarget Target, float BlendTime, bool bAlwaysValid)
	{
		// Only allow one focus target per actor. Note that these will only be used if camera subsequently snaps.
		for (int i = FocusTargets.Num() - 1; i >= 0; i--)
		{
			if (FocusTargets[i].Actor == Target.Actor)
				FocusTargets.RemoveAtSwap(i);
		}
		FocusTargets.Add(Target);

		// Update the actual in game targets
		for (FKeepInViewTarget& PrevTarget : AllFocusTargets)
		{
			if (PrevTarget.FocusTarget.Actor == Target.Actor)
			{
				// We already have this target, update offsets and blend time
				PrevTarget.FocusTarget = Target;
				PrevTarget.BlendDuration = BlendTime;

				// If we were blending out we will need to set the blend in origin
				if (PrevTarget.IsBlendingOut())
				{
					PrevTarget.WorldBlendInOrigin = WorldTransform.TransformPosition(PrevTarget.LocalLocation);
					PrevTarget.BlendFraction.SnapTo(0.f);
				}

				// Update blend state. Note that we do not change to blend in if target was blending out due to being invalid.
				if (bAlwaysValid)
					PrevTarget.BlendState = EKeepInViewBlendState::AlwaysValid;
				else if (PrevTarget.BlendState == EKeepInViewBlendState::ForceBlendOut)
					PrevTarget.BlendState = EKeepInViewBlendState::BlendIn;

				// We can only have one focus target per actor
				return;
			}
		}
		// Add new target with zero blend fraction
		FKeepInViewTarget NewTarget(Target, this, PlayerUser, 0.f);
		NewTarget.BlendDuration = BlendTime;
		NewTarget.BlendState = bAlwaysValid ? EKeepInViewBlendState::AlwaysValid : EKeepInViewBlendState::BlendIn;
		
		// Blend in from camera center
		FHazeCameraKeepInViewSettings Settings;
		GetSettings(Settings);
		NewTarget.WorldBlendInOrigin = WorldTransform.TransformPosition(GetLocalCenterLocation(Settings));
		NewTarget.BlendFraction.SnapTo(0.f);

		AllFocusTargets.Add(NewTarget);
	}

    UFUNCTION()
    void BlendOutTarget(AHazeActor Actor, float BlendTime, EHazeSelectPlayer AffectedPlayer = EHazeSelectPlayer::Both, bool bRemoveAfterBlendOut = false)
    {
		if (AffectedPlayer == EHazeSelectPlayer::None)
			return;

        TArray<UCameraKeepInViewComponent> KeepInViews = GetAllKeepInViewCameras();
        for (UCameraKeepInViewComponent KeepInView : KeepInViews)
        {
			if ((KeepInView != nullptr) && (KeepInView.IsUsedByPlayer(AffectedPlayer)))
				KeepInView.BlendOutTargetInternal(Actor, BlendTime, bRemoveAfterBlendOut);
        }
    }

	private void BlendOutTargetInternal(AHazeActor Actor, float BlendTime, bool bRemoveAfterBlendOut)
	{
		// Remove base focus targets. Note that these will only be used if camera subsequently snaps.
		for (int i = FocusTargets.Num() - 1; i >= 0; i--)
		{
			if (FocusTargets[i].Actor == Actor)
				FocusTargets.RemoveAtSwap(i);
		}

		// Update the actual in game targets
		for (FKeepInViewTarget& PrevTarget : AllFocusTargets)
		{
			if (PrevTarget.FocusTarget.Actor == Actor)
			{
				// Set this target to blend out over given time
				PrevTarget.BlendDuration = BlendTime;
				if (!PrevTarget.IsBlendingOut())
				{
					FHazeCameraKeepInViewSettings Settings;
					GetSettings(Settings);
					PrevTarget.LocalBlendOutOrigin = PrevTarget.LocalLocation;
					PrevTarget.BlendFraction.SnapTo(1.f);
				}
				PrevTarget.BlendState = EKeepInViewBlendState::ForceBlendOut;
				PrevTarget.bRemoveAfterBlendOut = bRemoveAfterBlendOut;
			}
		}
	}

    UFUNCTION()
    void SetLookOffset(FRotator Offset, float Duration, UObject Instigator = nullptr, EHazeCameraPriority Priority = EHazeCameraPriority::Script)
    {
        FHazeCameraBlendSettings Blend = FHazeCameraBlendSettings(Duration);
        FHazeCameraKeepInViewSettings Settings;
        Settings.bUseLookOffset = true;
        Settings.LookOffset = Offset;

        // Make sure this affect all players using the component
        TArray<AHazePlayerCharacter> Players = Game::GetPlayers();
        for (AHazePlayerCharacter Player : Players)
        {
            if (Player.GetCurrentlyUsedCamera().GetOwner() == GetOwner())
                Player.ApplyCameraKeepInViewSettings(Settings, Blend, Instigator, Priority);
        }
    }

    UFUNCTION()
    void SetPrimaryTarget(FHazeFocusTarget Target, bool bSetForAllUsers = true)
    {
		if (bSetForAllUsers)
		{
			// Make sure this affect all players using the component
			TArray<UCameraKeepInViewComponent> KeepInViews = GetAllKeepInViewCameras();
			for (UCameraKeepInViewComponent KeepInView : KeepInViews)
			{
				KeepInView.SetPrimaryTargetInternal(Target);
			}
		}
		else
		{
			// Only this camera
			SetPrimaryTargetInternal(Target);
		}
    }

	private void SetPrimaryTargetInternal(FHazeFocusTarget Target)
	{
		PrimaryTarget = Target;
        if (PrimaryTarget.IsValid())
		{
			// Remove any keep in view targets using same actor as primary, but keep blend values 
			FKeepInViewTarget CurTarget;
			for (int i = AllFocusTargets.Num() - 1; i >= 0; i--)
			{
				if (PrimaryTarget.Actor == AllFocusTargets[i].FocusTarget.Actor)
				{
					CurTarget = AllFocusTargets[i];
					AllFocusTargets.RemoveAtSwap(i);
				}
			}
			FKeepInViewTarget NewTarget = FKeepInViewTarget(PrimaryTarget, this, PlayerUser);
			NewTarget.BlendDuration = CurTarget.BlendDuration;
			NewTarget.BlendFraction = CurTarget.BlendFraction;
            AllFocusTargets.Add(NewTarget);
		}
	}

    UFUNCTION()
    void RemoveTarget(AHazeActor Target, EHazeSelectPlayer AffectedPlayer = EHazeSelectPlayer::Both)
    {
        if (Target == nullptr)
            return;

		if (AffectedPlayer == EHazeSelectPlayer::None)
			return;

        TArray<UCameraKeepInViewComponent> KeepInViews = GetAllKeepInViewCameras();
        for (UCameraKeepInViewComponent KeepInView : KeepInViews)
        {
			if ((KeepInView != nullptr) && (KeepInView.IsUsedByPlayer(AffectedPlayer)))
				KeepInView.RemoveTargetInternal(Target);
        }
	}

	void RemoveTargetInternal(AHazeActor Target)
	{
		for (int32 i = FocusTargets.Num() - 1; i >= 0; i--)
		{
			if (FocusTargets[i].Actor == Target)
				FocusTargets.RemoveAtSwap(i);
		}

		if (PrimaryTarget.Actor == Target)
			PrimaryTarget = FHazeFocusTarget();

		for (int32 i = AllFocusTargets.Num() - 1; i >= 0; i--)
		{
			if (AllFocusTargets[i].FocusTarget.Actor == Target)
				AllFocusTargets.RemoveAtSwap(i);
		}
    }

    UFUNCTION()
    void SetAxisFreedomFactor(FVector Factor, FHazeFocusTarget Center, EHazeSelectPlayer AffectedPlayer = EHazeSelectPlayer::Both)
    {
		if (AffectedPlayer == EHazeSelectPlayer::None)
			return;

        TArray<UCameraKeepInViewComponent> KeepInViews = GetAllKeepInViewCameras();
        for (UCameraKeepInViewComponent KeepInView : KeepInViews)
        {
			if ((KeepInView != nullptr) && (KeepInView.IsUsedByPlayer(AffectedPlayer)))
			{
				KeepInView.AxisFreedomFactor = Factor;
				if (Center.IsValid())
					KeepInView.AxisFreedomCenter = Center;
			}
		}
    }

    UFUNCTION()
    void SetAxisFreedomCenter(FHazeFocusTarget FocusTarget, EHazeSelectPlayer AffectedPlayer = EHazeSelectPlayer::Both)
    {
		if (!FocusTarget.IsValid())
			return;
		if (AffectedPlayer == EHazeSelectPlayer::None)
			return;

        TArray<UCameraKeepInViewComponent> KeepInViews = GetAllKeepInViewCameras();
        for (UCameraKeepInViewComponent KeepInView : KeepInViews)
        {
			if ((KeepInView != nullptr) && (KeepInView.IsUsedByPlayer(AffectedPlayer)))
			{
				KeepInView.AxisFreedomCenter = FocusTarget;
			}
		}
	}

    UFUNCTION()
    void SetCurrentAccelerationDuration(float Seconds)
    {
        // Make sure this affect all players using the component
        TArray<UCameraKeepInViewComponent> KeepInViews = GetAllKeepInViewCameras();
        for (UCameraKeepInViewComponent KeepInView : KeepInViews)
        {
            KeepInView.CurrentAccelerationDuration.Velocity = 0.f;
            KeepInView.CurrentAccelerationDuration.Value = Seconds;
        }
    }

    UFUNCTION()
    void ResetCurrentAccelerationDuration()
    {
        // Make sure this affect all players using the component
        TArray<UCameraKeepInViewComponent> KeepInViews = GetAllKeepInViewCameras();
        for (UCameraKeepInViewComponent KeepInView : KeepInViews)
        {
            KeepInView.CurrentAccelerationDuration.Velocity = 0.f;
            KeepInView.CurrentAccelerationDuration.Value = AccelerationDuration;
        }
    }

    UFUNCTION()
    void SetPlayerOffsets(FVector WorldOffset = FVector::ZeroVector, FVector LocalOffset = FVector::ZeroVector, FVector ViewOffset = FVector::ZeroVector)
    {
        // Make sure this affect all players using the component
        TArray<UCameraKeepInViewComponent> KeepInViews = GetAllKeepInViewCameras();
        for (UCameraKeepInViewComponent KeepInView : KeepInViews)
        {
            KeepInView.PlayerFocusProperties.WorldOffset = WorldOffset;
            KeepInView.PlayerFocusProperties.LocalOffset = LocalOffset;
            KeepInView.PlayerFocusProperties.ViewOffset = ViewOffset;
			for (FKeepInViewTarget& Target : AllFocusTargets)
			{
				if (Target.FocusTarget.Actor.IsA(AHazePlayerCharacter::StaticClass()))
				{
					Target.FocusTarget.WorldOffset = WorldOffset;
					Target.FocusTarget.LocalOffset = LocalOffset;
					Target.FocusTarget.ViewOffset = ViewOffset;
				}
			}
		}
    }
}

UFUNCTION(BlueprintPure)
UCameraKeepInViewComponent GetCurrentlyUsedKeepInViewComponent(AHazePlayerCharacter Player)
{
	UHazeCameraParentComponent KeepInView = GetCurrentlyUsedCameraParentComponent(Player, TSubclassOf<UHazeCameraParentComponent>(UCameraKeepInViewComponent::StaticClass()));
	if (KeepInView == nullptr)
		return nullptr;
	return Cast<UCameraKeepInViewComponent>(KeepInView);
}
