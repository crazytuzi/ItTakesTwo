import Vino.Movement.Components.GroundPound.GroundpoundedCallbackComponent;
import Vino.Movement.Components.ImpactCallback.ActorImpactedCallbackGlobalBindFunctions;
import Cake.LevelSpecific.Garden.LevelActors.FrogPond.FrogPondWaterPlane;
import Vino.Movement.Components.MovementComponent;

UCLASS(Abstract)
class AWaterPump : AHazeActor
{
	UPROPERTY(RootComponent, DefaultComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UStaticMeshComponent BaseMesh;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent HandleRoot;

	UPROPERTY(DefaultComponent, Attach = HandleRoot)
	UStaticMeshComponent HandleMesh;

	UPROPERTY(DefaultComponent, Attach = HandleMesh)
	UStaticMeshComponent LeftPlatform;

	UPROPERTY(DefaultComponent, Attach = HandleMesh)
	UStaticMeshComponent RightPlatform;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UArrowComponent Nozzle;

	UPROPERTY(DefaultComponent, Attach = Nozzle)
	UNiagaraComponent SplashComp;

	UPROPERTY(DefaultComponent)
	UHazeInheritPlatformVelocityComponent InheritVelocityComp;
	default InheritVelocityComp.bInheritVerticalVelocity = true;
	default InheritVelocityComp.bInheritHorizontalVelocity = true;

	UPROPERTY()
	AFrogPondWaterPlane WaterPlane;

	float DesiredRot = 0.f;
	float CurrentRot = 0.f;
	float MaximumRot = 35.f;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		FActorGroundPoundedDelegate GroundPoundDelegate;
		GroundPoundDelegate.BindUFunction(this, n"PumpGroundPounded");
		BindOnActorGroundPounded(this, GroundPoundDelegate);
	}

	UFUNCTION()
	void PumpGroundPounded(AHazePlayerCharacter Player)
	{
		UHazeMovementComponent MoveComp = UHazeMovementComponent::Get(Player);
		if (MoveComp == nullptr)
			return;

		UPrimitiveComponent PrimitiveComp = MoveComp.DownHit.Component;
		if (PrimitiveComp == nullptr)
			return;

		if (PrimitiveComp == LeftPlatform)
			DesiredRot = MaximumRot;
		else if (PrimitiveComp == RightPlatform)
			DesiredRot = -MaximumRot;
		else
			return;

		float DesiredRotDifference = FMath::Abs(CurrentRot - DesiredRot);

		if (DesiredRotDifference > 45.f)
		{
			PumpWater();
			if (WaterPlane != nullptr)
				WaterPlane.Pumped();
		}
	}

	void PumpWater()
	{
		SplashComp.Activate();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		DesiredRot = FMath::FInterpTo(DesiredRot, 0.f, DeltaTime, 0.5f);
		CurrentRot = FMath::FInterpTo(CurrentRot, DesiredRot, DeltaTime, 1.f);
		CurrentRot = FMath::Clamp(CurrentRot, -MaximumRot, MaximumRot);

		HandleRoot.SetRelativeRotation(FRotator(CurrentRot, HandleRoot.RelativeRotation.Yaw, 0.f));
	}
}
