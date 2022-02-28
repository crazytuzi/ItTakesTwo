import Vino.Movement.Components.ImpactCallback.ActorImpactedCallbackGlobalBindFunctions;
import Vino.PlayerHealth.PlayerHealthStatics;
import Vino.Bounce.BounceComponent;

class AHiHatPedal : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent MeshBase;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent PedalMeshRoot;

	UPROPERTY(DefaultComponent, Attach = PedalMeshRoot)
	UStaticMeshComponent PedalMesh;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent BounceRoot;

	UPROPERTY(DefaultComponent, Attach = BounceRoot)
	USceneComponent CylinderMeshRoot;

	UPROPERTY(DefaultComponent, Attach = BounceRoot)
	UBounceComponent BounceComp; 

	UPROPERTY(DefaultComponent, Attach = CylinderMeshRoot)
	UStaticMeshComponent Cylinder;

	UPROPERTY(DefaultComponent, Attach = CylinderMeshRoot)
	UStaticMeshComponent HHCymb01;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent HHCymb02;

	FVector CylStartLoc = FVector::ZeroVector;
	FVector CylTargetLoc = FVector::ZeroVector;

	UPROPERTY()
	TSubclassOf<UPlayerDeathEffect> DeathEffect;

	FRotator PedalStartRot = FRotator(25.f, 0.f, 0.f);
	FRotator PedalTargetRot = FRotator(5.f, 0.f, 0.f);

	FRotator StickStartRot = FRotator::ZeroRotator;
	FRotator StickTargetRot = FRotator(-60.f, 0.f, 0.f);

	float BounceRootZLastTick = 0.f;
	float BounceVelocity = 0.f;
	bool bIsMoving = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		CylStartLoc = CylinderMeshRoot.RelativeLocation;
		CylTargetLoc = CylStartLoc;
		CylTargetLoc.Z -= 350.f;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		float Lerp = FMath::GetMappedRangeValueClamped(FVector2D(0.f, -350.f), FVector2D(0.f, 1.f), BounceRoot.RelativeLocation.Z);
		PedalMeshRoot.SetRelativeRotation(FRotator(FMath::Lerp(25.f, 0.f, Lerp), 0.f, 0.f));

		BounceVelocity = FMath::Abs((BounceRoot.RelativeLocation.Z - BounceRootZLastTick) / DeltaTime);

		if (BounceVelocity > 250.f)
			bIsMoving = true;
		else
			bIsMoving = false;		

		BounceRootZLastTick = BounceRoot.RelativeLocation.Z;
	}
}