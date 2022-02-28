import Cake.LevelSpecific.Garden.ControllablePlants.Tomato.Tomato;
import Cake.LevelSpecific.Garden.ControllablePlants.Tomato.TomatoTargetComponent;
import Cake.LevelSpecific.Garden.ControllablePlants.Tomato.TomatoDashTargetComponent;

class UTomatoDebugCapability : UHazeDebugCapability
{
	default TickGroup = ECapabilityTickGroups::ActionMovement;
	default TickGroupOrder = 9;

	ATomato Tomato;
	UTomatoSettings Settings;

	bool bDrawPhysics = false;
	bool bDrawTargeting = false;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Tomato = Cast<ATomato>(Owner);
		Settings = UTomatoSettings::GetSettings(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void SetupDebugVariables(FHazePerActorDebugCreationData& DebugValues) const
	{
		FHazeDebugFunctionCallHandler TogleDrawPhysicsHandler = DebugValues.AddFunctionCall(n"ToggleDrawPhysics", "Toggle Draw Physics");
		FHazeDebugFunctionCallHandler TogleDrawTargetingHandler = DebugValues.AddFunctionCall(n"ToggleDrawTargeting", "Toggle Draw Targeting");

		TogleDrawPhysicsHandler.AddActiveUserButton(EHazeDebugActiveUserCategoryButtonType::DPadLeft, n"Tomato");
		TogleDrawTargetingHandler.AddActiveUserButton(EHazeDebugActiveUserCategoryButtonType::DPadDown, n"Tomato");
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(bDrawPhysics)
			DrawPhysics();

		if(bDrawTargeting)
			DrawTargeting();
	}

	UFUNCTION()
	private void ToggleDrawPhysics()
	{
		bDrawPhysics = !bDrawPhysics;
	}

	UFUNCTION()
	private void ToggleDrawTargeting()
	{
		bDrawTargeting = !bDrawTargeting;
	}

	private void DrawPhysics()
	{
		for(FTomatoBounceInfo BounceInfo : Tomato.BounceList)
		{

			const float ArrowLength = 400.0f;
			const float ArrowSize = 5.0f;
			const float ArrowDuration = 2.0f;
			const FVector StartLocation = Owner.ActorLocation;
			const FVector FacingDirection2D = Tomato.Velocity.GetSafeNormal2D();
			const FVector ReflectedVector = FMath::GetReflectionVector(FacingDirection2D, BounceInfo.HitNormal);
			System::DrawDebugArrow(StartLocation, StartLocation + (FacingDirection2D * ArrowLength), ArrowSize, FLinearColor::Red, ArrowDuration);
			System::DrawDebugArrow(StartLocation, StartLocation + (ReflectedVector * ArrowLength), ArrowSize, FLinearColor::Green, ArrowDuration);
		}
	}

	private void DrawTargeting()
	{
		System::DrawDebugSphere(Tomato.TomatoRoot.WorldLocation, Settings.HitRadius, 12, FLinearColor::Green);

		UTomatoTargetComponent TargetComp = UTomatoTargetComponent::Get(Tomato.OwnerPlayer);

		if(TargetComp == nullptr)
			return;

		TargetComp.DrawDebug();

		for(int Index = 0, Num = TargetComp.NumTargets; Index < Num; ++Index)
		{
			AHazeActor Target = TargetComp.GetTarget(Index);

			if(Target == nullptr)
				continue;

			UTomatoDashTargetComponent DashTarget = UTomatoDashTargetComponent::Get(Target);

			if(DashTarget == nullptr)
				continue;

			if(DashTarget.IsBeingDestroyed())
				continue;
			
			System::DrawDebugSphere(Target.ActorCenterLocation, DashTarget.HitRadius, 12, FLinearColor::Red);
		}
	}
}
