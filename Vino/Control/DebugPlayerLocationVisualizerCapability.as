

class UDebugPlayerLocationVisualizerCapability : UHazeDebugCapability
{
	default CapabilityTags.Add(n"Debug");
	default CapabilityDebugCategory = n"Debug";

	AHazePlayerCharacter PlayerOwner;
	bool bIsActive = false;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		PlayerOwner = Cast<AHazePlayerCharacter>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void SetupDebugVariables(FHazePerActorDebugCreationData& DebugValues) const
	{
		FHazeDebugFunctionCallHandler Handler = DebugValues.AddFunctionCall(n"NetToggleVisualizer", "Toggle Visuals");
		Handler.AddActiveUserButton(EHazeDebugActiveUserCategoryButtonType::DPadDown, n"Movement");

		DebugValues.AddDebugSettingsFlag(n"DrawPlayerDebugShapes", "Will draw the players shapes.");
	}

	UFUNCTION(NetFunction)
	void NetToggleVisualizer()
	{			
		bIsActive = !bIsActive;		
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!PlayerOwner.GetDebugFlag(n"DrawPlayerDebugShapes") && !bIsActive)
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
    EHazeNetworkDeactivation ShouldDeactivate() const
    {
		if(!PlayerOwner.GetDebugFlag(n"DrawPlayerDebugShapes") && !bIsActive)
       		return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
    }	

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		const FVector OffsetUp = (PlayerOwner.GetMovementWorldUp() * PlayerOwner.CapsuleComponent.GetScaledCapsuleHalfHeight());

		const FTransform ActorTransform = PlayerOwner.GetActorTransform();
		System::DrawDebugCoordinateSystem(
			ActorTransform.Location,
			 ActorTransform.Rotator(), 
			 500.f, 0.f, 10.f);
		
		FLinearColor CollisionColor = PlayerOwner.GetActorEnableCollision() && PlayerOwner.CapsuleComponent.IsCollisionEnabled() ? FLinearColor::Green : FLinearColor::Red;
		const FTransform CapsuleTransform = PlayerOwner.CapsuleComponent.GetWorldTransform();
		System::DrawDebugCapsule(
			CapsuleTransform.GetLocation(), 
			PlayerOwner.CapsuleComponent.GetScaledCapsuleHalfHeight(), 
			PlayerOwner.CapsuleComponent.GetScaledCapsuleRadius(),
			CapsuleTransform.Rotator(),
			CollisionColor,
			0.f, 4.f);

		System::DrawDebugArrow(
			PlayerOwner.GetActorCenterLocation(), 
			CapsuleTransform.GetLocation() + OffsetUp, 
			25.f, 
			FLinearColor::Gray,
			0, 3.f);

		const FTransform MeshTransform = PlayerOwner.Mesh.GetWorldTransform();
		System::DrawDebugBox(
			MeshTransform.GetLocation() + OffsetUp, 
			FVector(PlayerOwner.Mesh.GetBoundsRadius()),
			FLinearColor::White,
			CapsuleTransform.Rotator(),
			0.f, 3.f);

		System::DrawDebugArrow(
			PlayerOwner.GetActorCenterLocation(), 
			MeshTransform.GetLocation() + OffsetUp, 
			25.f, 
			FLinearColor::White,
			0, 3.f);
		
		FString PlayerName = "Player: " + PlayerOwner.GetName();
		FString ActorTransformText = "\nActor World Transform: " + ActorTransform;
		FString CapsuleTransformText = "\nCapsule Relative Transform: " + PlayerOwner.CapsuleComponent.GetRelativeTransform();
		FString MeshTransformText = "\nMesh Relative Transform: " + PlayerOwner.Mesh.GetRelativeTransform();
		PrintToScreen(PlayerName + ActorTransformText + CapsuleTransformText + MeshTransformText, 0.f, PlayerOwner.GetDebugColor());
	}
}