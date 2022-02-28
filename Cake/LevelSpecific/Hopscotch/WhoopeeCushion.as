import Vino.Movement.Components.MovementComponent;
import Peanuts.Spline.SplineComponent;
import Vino.Trajectory.TrajectoryComponent;
import Vino.Movement.Helpers.BurstForceStatics;
import Cake.LevelSpecific.Hopscotch.HopscotchDungeon.HopscotchDungeonWhoopeeBall;
import Vino.Pickups.PlayerPickupComponent;

event void FCushionInflated(AHazePlayerCharacter PlayerToLaunch);
event void FLaunchBall();

class AWhoopeeCushion : AHazeActor
{
    UPROPERTY(RootComponent, DefaultComponent)
    USceneComponent Root;

    UPROPERTY(DefaultComponent, Attach = Root)
	UHazeSkeletalMeshComponentBase CollisionMesh;
	default CollisionMesh.bHiddenInGame = true;

	UPROPERTY(DefaultComponent, Attach = Root)
	UPoseableMeshComponent PoseableMesh;
	
    UPROPERTY(DefaultComponent, Attach = Root)
    UBoxComponent BoxCollision;
	default BoxCollision.RelativeLocation = FVector(0.f, 0.f, 35.f);
	default BoxCollision.BoxExtent = FVector(180.f, 175.f, 150.f);

	UPROPERTY(DefaultComponent, Attach = Root)
	UArrowComponent VerticalBounceDirection;

	UPROPERTY()
	AActor ConnectedBallAchor;

	UPROPERTY()
	AHopscotchDungeonWhoopeeBall ConnectedWhoopeeBall;
    
    UPROPERTY()
    FHazeTimeLike InflateTimeline;
    default InflateTimeline.Duration = 0.1f;

    UPROPERTY()
    FHazeTimeLike DeflateTimeline;
    default DeflateTimeline.Duration = 1.f;

	UPROPERTY(Category = "Bounce Properties")
    float VerticalVelocity = 1500.f;

    UPROPERTY(Category = "Bounce Properties")
    float HorizontalVelocityModifier = 0.5f;

    UPROPERTY(Category = "Bounce Properties")
    float MaximumHorizontalVelocity = 500.f;

    UPROPERTY(Category = "LaunchProperties")
    AActor ActorToLaunchTo;

    UPROPERTY(Category = "LaunchProperties")
    float Duration;

    UPROPERTY()
    FCushionInflated CushionInflatedEvent;

	UPROPERTY(EditDefaultsOnly, Category = "Bounce Properties")
    TSubclassOf<UHazeCapability> BouncePadCapabilityClass;

    float DeflatedZValue = .2f;
    float InflatedZValue = 1.f;

    bool bCanLaunchPlayer = true;

    UFUNCTION(BlueprintEvent)
    void BP_InflateCushion()
    {}

    UFUNCTION(BlueprintEvent)
    void BP_DeflateCushion()
    {}

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
        InflateTimeline.BindUpdate(this, n"InflateTimelineUpdate");
        InflateTimeline.BindFinished(this, n"InflateTimelineFinished");

        DeflateTimeline.BindUpdate(this, n"DeflateTimelineUpdate");

		PoseableMesh.SetBoneScaleByName(n"Cushion", FVector(1.f, 1.f, 0.2f), EBoneSpaces::WorldSpace);

        CollisionMesh.SetRelativeScale3D(FVector(CollisionMesh.RelativeScale3D.X, CollisionMesh.RelativeScale3D.Y, DeflatedZValue));
		Capability::AddPlayerCapabilityRequest(BouncePadCapabilityClass);
	}

	UFUNCTION(BlueprintOverride)
    void EndPlay(EEndPlayReason Reason)
    {
        Capability::RemovePlayerCapabilityRequest(BouncePadCapabilityClass);
    }

    UFUNCTION()
    void InflateTimelineUpdate(float CurrentValue)
    {
        CollisionMesh.SetRelativeScale3D(FVector(CollisionMesh.RelativeScale3D.X, CollisionMesh.RelativeScale3D.Y, FMath::Lerp(DeflatedZValue, InflatedZValue, CurrentValue)));
		PoseableMesh.SetBoneScaleByName(n"Cushion", FVector(1.f, 1.f, FMath::Lerp(DeflatedZValue, InflatedZValue, CurrentValue)), EBoneSpaces::WorldSpace);
    }

    UFUNCTION()
    void InflateTimelineFinished(float CurrentValue)
    {
        
    }

    UFUNCTION()
    void DeflateTimelineUpdate(float CurrentValue)
    {
        CollisionMesh.SetRelativeScale3D(FVector(CollisionMesh.RelativeScale3D.X, CollisionMesh.RelativeScale3D.Y, FMath::Lerp(InflatedZValue, DeflatedZValue, CurrentValue)));
		PoseableMesh.SetBoneScaleByName(n"Cushion", FVector(1.f, 1.f, FMath::Lerp(InflatedZValue, DeflatedZValue, CurrentValue)), EBoneSpaces::WorldSpace);
    }

    UFUNCTION()
    void InflateCushion(AHazePlayerCharacter Player)
    {	
		if (DeflateTimeline.IsPlaying())
            DeflateTimeline.Stop();

        InflateTimeline.PlayFromStart();
        BP_InflateCushion();
		
		if (Player != nullptr)
		{
			LaunchPlayer(Player);
		}		  
    }

	AHazePlayerCharacter CushionOverlapCheck()
	{
		TArray<AActor> ActorArray;
        BoxCollision.GetOverlappingActors(ActorArray);

        for (AActor Actor : ActorArray)
        {
            AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(Actor);
            if (Player != nullptr)
            {
				return Player;
            }
        }
		return nullptr;        
	}

	UFUNCTION()
	void LaunchPlayer(AHazePlayerCharacter Player)
	{
		if (Player == nullptr)
			return;

		CushionInflatedEvent.Broadcast(Player);
		Player.SetCapabilityAttributeVector(n"VerticalVelocityDirection", VerticalBounceDirection.ForwardVector);
		Player.SetCapabilityAttributeValue(n"VerticalVelocity", VerticalVelocity);
		Player.SetCapabilityAttributeValue(n"HorizontalVelocityModifier", HorizontalVelocityModifier);
		Player.MovementComponent.StopMovement();
		Player.SetCapabilityActionState(n"Bouncing", EHazeActionState::Active);
	}

    UFUNCTION()
    void DeflateCushion()
    {
        DeflateTimeline.PlayFromStart();
        BP_DeflateCushion();
    }
}