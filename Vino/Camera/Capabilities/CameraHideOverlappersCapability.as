import Vino.Camera.Components.CameraUserComponent;

class UCameraHideOverlappersCapability : UHazeCapability
{
	UCameraUserComponent User;
	UCameraUserComponent OtherUser;
	AHazePlayerCharacter PlayerUser;

	default CapabilityTags.Add(CameraTags::Camera);
	default CapabilityTags.Add(n"PlayerDefault");
	default CapabilityTags.Add(n"CameraHideOverlappers");

	default TickGroup = ECapabilityTickGroups::LastDemotable;
    default CapabilityDebugCategory = CameraTags::Camera;

	TArray<AActor> HiddenActors;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		User = UCameraUserComponent::Get(Owner);
		PlayerUser = Cast<AHazePlayerCharacter>(Owner);
		OtherUser = UCameraUserComponent::Get(PlayerUser.OtherPlayer);
		User.OnReset.AddUFunction(this, n"OnReset");
		User.UpdateHideOnOverlap.AddUFunction(this, n"OnForcedUpdate");
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (IsCutsceneFullyBlendedIn())
			return EHazeNetworkActivation::DontActivate;

		if (SceneView::IsFullScreen() && (SceneView::GetFullScreenPlayer() != PlayerUser))
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (IsCutsceneFullyBlendedIn())
			return EHazeNetworkDeactivation::DeactivateLocal;

		if (SceneView::IsFullScreen() && (SceneView::GetFullScreenPlayer() != PlayerUser))
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	bool IsCutsceneFullyBlendedIn() const
	{
		AHazePlayerCharacter TestPlayer = PlayerUser;

		if (PlayerUser.ActiveLevelSequenceActor == nullptr)
			return false;
		UHazeCameraComponent CurCam = User.GetCurrentCamera();
		if (CurCam.IsControlledByInput())
			return false;
		if (PlayerUser.GetRemainingBlendTime(CurCam) > 0.1f)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Reset();
	}

	UFUNCTION(NotBlueprintCallable)
	void OnReset()
	{
		Reset();
	}

	UFUNCTION(NotBlueprintCallable)
	void OnForcedUpdate()
	{
		Reset();
	}

	void Reset()
	{
		HiddenActors.Empty();
		User.ShowComponentsByInstigator(this);			
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FVector ViewLocation = PlayerUser.GetViewLocation();
		float OverlapRadius = 20.f * FMath::Min(1.f, PlayerUser.GetActorScale3D().Z);
		TArray<UPrimitiveComponent> ObstructingComponents;
		TArray<AActor> ActorsToIgnore;
		Trace::SphereOverlapComponentsMultiByChannel(ObstructingComponents, ViewLocation, OverlapRadius, ETraceTypeQuery::Visibility, ActorsToIgnore, UPrimitiveComponent::StaticClass());
		Trace::SphereOverlapComponentsMultiByChannel(ObstructingComponents, ViewLocation, OverlapRadius, ETraceTypeQuery::Camera, ActorsToIgnore, UPrimitiveComponent::StaticClass());
		TArray<AActor> ActorsToShow = HiddenActors;
		TArray<AActor> ActorsToHide;
		for (UPrimitiveComponent Comp : ObstructingComponents)
		{
			// Have we found an actor to hide? (note that currently we do not hide specific components of an actor)
			if (!Comp.HasTag(ComponentTags::HideOnCameraOverlap))
				continue;
		
			// Any currently hidden actors should stay hidden
			ActorsToShow.Remove(Comp.Owner); 
			if (!HiddenActors.Contains(Comp.Owner)) // We can't use bool return of Remove since there might be duplicates in obstructingcomps
			{
				// This actor was not previously hidden, so should be hidden now
				ActorsToHide.AddUnique(Comp.Owner);
			}
		}

		if (ActorsToHide.Num() > 0)
		{
			TArray<FHazeCameraHideForUserSlot>	HideSlots;
			HideSlots.Reserve(ActorsToHide.Num());
			for (AActor Actor : ActorsToHide)
			{
				// Hide characters completely, for others only hide those components 
				// with the HideOnCameraOverlap tag.
				FHazeCameraHideForUserSlot Hide;
				Hide.Actor = Actor;
				if (!Actor.IsA(AHazeCharacter::StaticClass()))
					Hide.ComponentTag = ComponentTags::HideOnCameraOverlap;
				// Players hide attached actors as well if they're set to HideOnCameraOverlap
				if (Actor.IsA(AHazePlayerCharacter::StaticClass()))
					Hide.AttacheesTag = ComponentTags::HideOnCameraOverlap;
				HideSlots.Add(Hide);
			}
			User.HideComponentsForUser(HideSlots, this);
			HiddenActors.Append(ActorsToHide);
		}

		if (ActorsToShow.Num() > 0)
		{
			// These are the actors which are no longer near view location
			TArray<FHazeCameraHideForUserSlot>	ShowSlots;
			ShowSlots.Reserve(ActorsToShow.Num());
			for (AActor Actor : ActorsToShow)
			{
				if (IsWithinHideThreshold(Actor, ViewLocation, OverlapRadius))
					continue; // Still too near to show.
				FHazeCameraHideForUserSlot Show;
				Show.Actor = Actor;
				if (Actor.IsA(AHazePlayerCharacter::StaticClass()))
					Show.AttacheesTag = ComponentTags::HideOnCameraOverlap;
				ShowSlots.Add(Show);
				HiddenActors.Remove(Actor);
			}
		 	User.ShowComponentsForUser(ShowSlots, this);
		}
	}	

	bool IsWithinHideThreshold(AActor Actor, FVector ViewLocation, float OverlapRadius)
	{
		// Actor with HideOnCameraOverlap capsule comps are only hidden 
		// when view is slightly further out from capsule 
		float HideRadius = OverlapRadius * 1.25f;		
		TArray<UActorComponent> Comps;
		Actor.GetAllComponents(UCapsuleComponent::StaticClass(), Comps);
		for (UActorComponent Comp : Comps)
		{
			UCapsuleComponent Capsule = Cast<UCapsuleComponent>(Comp);
			if (Capsule == nullptr)
				continue;
			if (!Capsule.HasTag(ComponentTags::HideOnCameraOverlap))
				continue;
			if (IsNearCapsule(ViewLocation, HideRadius, Capsule))
				return true;
		}
		// No capsule near enough, we can show actor
		return false;
	}

	bool IsNearCapsule(FVector Location, float NearRadius, UCapsuleComponent Capsule)
	{
		FVector CylinderTop = Capsule.WorldLocation + Capsule.UpVector * Capsule.ScaledCapsuleHalfHeight;
		FVector CylinderBottom = Capsule.WorldLocation - Capsule.UpVector * Capsule.ScaledCapsuleHalfHeight;
		FVector ClosestCapsuleCenterLoc;
		float Dummy;
		Math::ProjectPointOnLineSegment(CylinderTop, CylinderBottom, Location, ClosestCapsuleCenterLoc, Dummy);
		return ClosestCapsuleCenterLoc.IsNear(Location, NearRadius + Capsule.GetScaledCapsuleRadius());
	}
}

