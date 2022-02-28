import Cake.LevelSpecific.Shed.Vacuum.VacuumablePhysicsActor;
import Cake.LevelSpecific.Shed.Vacuum.VacuumableWeight;
import Cake.LevelSpecific.Shed.Vacuum.RobotVacuum;

event void FOnWeightLandedInBowl();

class AVacuumWeightBowl : AHazeActor
{
    UPROPERTY(RootComponent, DefaultComponent)
    USceneComponent Root;

    UPROPERTY(DefaultComponent, Attach = Root)
    USceneComponent AttachmentPoint;

	UPROPERTY(DefaultComponent, Attach = AttachmentPoint)
	USceneComponent BagRoot;

	UPROPERTY(DefaultComponent, Attach = BagRoot)
	UPoseableMeshComponent BagMesh;

	UPROPERTY(DefaultComponent, Attach = BagRoot)
	UBoxComponent FunnelTrigger;

	UPROPERTY(DefaultComponent, Attach = BagRoot)
	USceneComponent WeightTargetPoint;

    TArray<AHazeActor> ActorsInBowl;

	UPROPERTY()
	ARobotVacuum RobotVacuum;

    FVector StartLocation;

    UPROPERTY()
    FOnWeightLandedInBowl OnWeightLandedInBowl;

	UPROPERTY()
	FOnWeightLandedInBowl OnFullyWeighedDown;

	int WeightsInBowl = 0;
	float TotalOffset = 0.f;

	UPROPERTY(NotEditable)
	bool bFullyWeighedDown = false;

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
        StartLocation = BagMesh.GetBoneLocationByName(n"BagBelly", EBoneSpaces::ComponentSpace);
        
        FunnelTrigger.OnComponentBeginOverlap.AddUFunction(this, n"EnterBowl");
    }

    UFUNCTION(NotBlueprintCallable)
	void EnterBowl(UPrimitiveComponent OverlappedComponent, AActor OtherActor, UPrimitiveComponent OtherComponent, int OtherBodyIndex, bool bFromSweep, FHitResult& Hit)
    {
		if (!HasControl())
			return;

        AVacuumableWeight WeightActor = Cast<AVacuumableWeight>(OtherActor);
        if(WeightActor != nullptr && WeightActor.bShotFromHose)
        {
			NetPutWeightInBowl(WeightActor);
        }
    }

	UFUNCTION(NetFunction)
	void NetPutWeightInBowl(AVacuumableWeight Weight)
	{
		ActorsInBowl.Add(Weight);
		OnWeightLandedInBowl.Broadcast();
		Weight.LandInWeightBowl(WeightTargetPoint);
		WeightsInBowl++;

		float Multiplier = WeightsInBowl == 1 ? 200.f : 125.f;
		TotalOffset += Multiplier;
		TotalOffset = FMath::Clamp(TotalOffset, 0.f, 1075.f);
		RobotVacuum.VerticalOffset = -TotalOffset;

		if (TotalOffset >= 1075.f && !bFullyWeighedDown)
		{
			bFullyWeighedDown = true;
			OnFullyWeighedDown.Broadcast();
		}
	}

    UFUNCTION(BlueprintOverride)
    void Tick(float DeltaTime)
    {
		FVector TargetOffset = StartLocation - FVector(0.f, 0.f, WeightsInBowl * 12.f);
        FVector Offset = FMath::VInterpTo(BagMesh.GetBoneLocationByName(n"BagBelly", EBoneSpaces::ComponentSpace), TargetOffset, DeltaTime, 5.f);
		BagMesh.SetBoneLocationByName(n"BagBelly", Offset, EBoneSpaces::ComponentSpace);
    }
}