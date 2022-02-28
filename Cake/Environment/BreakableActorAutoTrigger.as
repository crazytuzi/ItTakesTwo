import Cake.Environment.Breakable;
import Vino.Movement.Components.MovementComponent;

class ABreakableActorAutoTrigger : ABreakableActor
{
	UPROPERTY(DefaultComponent, Attach = BreakableComponent)
	UBoxComponent BreakableTrigger;

	UPROPERTY(DefaultComponent, Attach = BreakableComponent)
	UArrowComponent ArrowComponent;

	// Unless specified, AHazePlayerCharacter will be used for overlap tests
	UPROPERTY()
	TSubclassOf<AHazeActor> OverrideOverlapActorClass = AHazePlayerCharacter::StaticClass();

	UPROPERTY()
	bool bUseManualBreakParameters = false;

	UPROPERTY(Meta = (EditCondition = "bUseManualBreakParameters"))
	float Force = 30.f;

	UPROPERTY(Meta = (MakeEditWidget, EditCondition = "bUseManualBreakParameters"))
	FVector ForceDirection;

	UPROPERTY(Meta = (EditCondition = "bUseManualBreakParameters"))
	float ScatterForce = 10.f;

	UPROPERTY()
	float TriggerToMeshSizeRatio = 1.4f;

	UPROPERTY()
	bool bEnableBreakableMeshCollisions = false;

	FVector BreakageVelocity;

	UFUNCTION(BlueprintOverride)
    void ConstructionScript()
    {
		Super::ConstructionScript();

		if(BreakableComponent.StaticMesh == nullptr)
			return;

		// Set trigger size and center it
		BreakableTrigger.SetBoxExtent(BreakableComponent.StaticMesh.BoundingBox.Extent * TriggerToMeshSizeRatio);
		BreakableTrigger.SetRelativeLocation(BreakableComponent.StaticMesh.BoundingBox.Center);

		// Draw editor arrow
		if(bUseManualBreakParameters)
		{
			FVector CustomBreakVector = GetCustomBreakVector(false);
			ArrowComponent.SetWorldRotation(CustomBreakVector.GetSafeNormal().Rotation());
			ArrowComponent.SetWorldScale3D(FVector(1.25f, 1.f, 1.f));
			ArrowComponent.ArrowSize = CustomBreakVector.Size() / 100.f;
		}
		else
		{
			ArrowComponent.ArrowSize = 0.f;
		}
    }

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		// Bind overlap event
		if(OverrideOverlapActorClass.IsValid())
			BreakableTrigger.OnComponentBeginOverlap.AddUFunction(this, n"OnComponentBeginOverlap");

		// Turn off player-breakable collisions 
		if(!bEnableBreakableMeshCollisions)
			BreakableComponent.MainMesh.SetCollisionProfileName(n"NoCollision");
	}

	UFUNCTION()
	void OnComponentBeginOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
		UPrimitiveComponent OtherComponent, int OtherBodyIndex,
		bool bFromSweep, FHitResult& Hit)
	{
		if(!OtherActor.IsA(OverrideOverlapActorClass.Get()))
			return;

		BreakageVelocity = bUseManualBreakParameters ?
			GetCustomBreakVector(true) * Force :
			UHazeMovementComponent::Get(OtherActor).Velocity;

		FBreakableHitData BreakData;
		BreakData.DirectionalForce = BreakageVelocity;
		BreakData.HitLocation = Hit.ImpactPoint;
		BreakData.ScatterForce = ScatterForce;

		BreakableComponent.Break(BreakData);
	}

	FVector GetCustomBreakVector(bool bNormalized)
	{
		FVector CustomBreakVector = ActorTransform.TransformPosition(ForceDirection) - ActorLocation;
		if(bNormalized)
			CustomBreakVector.Normalize();

		return CustomBreakVector;
	}
}