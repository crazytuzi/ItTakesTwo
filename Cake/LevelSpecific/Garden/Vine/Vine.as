import Peanuts.Spline.SplineComponent;
import Cake.LevelSpecific.Garden.Vine.VineAttachmentPoint;
import Cake.LevelSpecific.Garden.Vine.VineImpactComponent;

UCLASS(Abstract)
class AVine : AHazeActor
{
    default PrimaryActorTick.bStartWithTickEnabled = false;

	UPROPERTY(RootComponent, DefaultComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UHazeSkeletalMeshComponentBase Mesh;

	UPROPERTY(DefaultComponent)
	UHazeDisableComponent DisableComp;
	default DisableComp.bDisabledAtStart = true;
	default DisableComp.bActorIsVisualOnly = true;

	UPROPERTY(Category = "Visuals")
	FName AttachPoint = n"BigLeaf1";

	UPROPERTY(Category = "Effects")
	UNiagaraSystem WhipImpactEffect;

	UPROPERTY(Category = "Effects")
	UNiagaraSystem AttachImpactEffect;

	// Animation Param
	UPROPERTY(NotEditable)
	EVineActiveType VineActiveType = EVineActiveType::Inactive;

	private FVector CurrentPoint;
	private bool bWhipping = false;
	private bool bLocked = false;

	AVineAttachmentPoint VineTargetPoint;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		
	}

	void ActivateVineWhip(FRotator OwnerRotation)
	{
		if(!bWhipping && !bLocked)
			EnableActor(nullptr);

		CurrentPoint = GetStartLocation();
		bWhipping = true;
		bLocked = false;
	}

	void ActivateVineLocked()
	{
		if(!bWhipping && !bLocked)
			EnableActor(nullptr);

		CurrentPoint = GetStartLocation();
		bWhipping = false;
		bLocked = true;
	}

	void DeactivateVine()
	{	
		if(bWhipping || bLocked)
			DisableActor(nullptr);

		bWhipping = false;	
		bLocked = false;	
		VineActiveType = EVineActiveType::Inactive;
	}

	UFUNCTION(BlueprintPure)
	FVector GetStartLocation()const property
	{
		return Game::GetCody().Mesh.GetSocketLocation(AttachPoint);
	}

	UFUNCTION(BlueprintPure)
	FVector GetTargetLocation() const property
	{
		return VineTargetPoint.GetActorLocation();
	}

	UFUNCTION(BlueprintPure)
	FVector GetCurrentLocation() const property
	{
		return CurrentPoint;
	}

	UFUNCTION(BlueprintPure)
	bool IsLocked()const
	{
		return bLocked;
	}

	UFUNCTION(BlueprintPure)
	bool IsWhipping()const
	{
		return bWhipping;
	}

	// Returns true until it has reached the target
	bool UpdateExtending(float DeltaTime, float ExtendSpeed)
	{
		//const float ExtendSpeed = bWhipping ? WhipExtendSpeed : AttachExtendSpeed;
		CurrentPoint = FMath::VInterpConstantTo(CurrentPoint, TargetLocation, DeltaTime, ExtendSpeed);
		return CurrentPoint.DistSquared(TargetLocation) > 1.f;
	}

	// Returns true until it has reached the hand again
	bool UpdateRetracting(float DeltaTime, float RetractSpeed)
	{
		const FVector Target = GetStartLocation();
		CurrentPoint = FMath::VInterpConstantTo(CurrentPoint, Target, DeltaTime, RetractSpeed);
		return CurrentPoint.DistSquared(Target) > 1.f;
	}

	void UpdateLockedOn()
	{
		CurrentPoint = TargetLocation;
	}

	float GetDistSqToStartLocation() const
	{
		const FVector Target = GetStartLocation();
		return CurrentPoint.DistSquared(Target);
	}

}
