import Cake.LevelSpecific.Music.LevelMechanics.Backstage.StudioAPuzzle.StudioAMovingPlatform;
import Vino.Movement.PlaneLock.PlaneLockStatics;

class UStudioAPlatformCapability : UHazeCapability
{
	default CapabilityTags.Add(n"StudioAPlatformCapability");

	default CapabilityDebugCategory = n"StudioAPlatformCapability";
	
	default TickGroup = ECapabilityTickGroups::ActionMovement;
	default TickGroupOrder = 100;

	AStudioAMovingPlatform MovingPlatform;
	UHazeMovementComponent MoveComp;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		MovingPlatform = Cast<AStudioAMovingPlatform>(Owner);
		MoveComp = UHazeMovementComponent::GetOrCreate(MovingPlatform);

		FPlaneConstraintSettings PlaneLockSettings;
		PlaneLockSettings.Origin = MovingPlatform.ActorLocation;
		PlaneLockSettings.Normal = FVector::UpVector;
		StartPlaneLockMovement(MovingPlatform, PlaneLockSettings);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (!IsActioning(n"ShouldMovePlatform"))
			return EHazeNetworkActivation::DontActivate;		

		if (MovingPlatform == nullptr)
			return EHazeNetworkActivation::DontActivate;

        return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{			
		if (!IsActioning(n"ShouldMovePlatform"))
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if (MovingPlatform == nullptr)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;
		
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
	
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		MovingPlatform.SubBassRoomCleared();
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
	
    }

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		if (!MoveComp.CanCalculateMovement())
			return;

		if (MovingPlatform.HasControl())
		{			
			FHazeFrameMovement MoveData = MoveComp.MakeFrameMovement(n"PlatformMove");
			
			TArray<float> MoveDir = MovingPlatform.GetMoveDirection();
			FVector PlatformMovement;
			PlatformMovement.X = MoveDir[1] - MoveDir[0];	
			PlatformMovement.Y = MoveDir[2] - MoveDir[3];
			PlatformMovement.Z = 0.f;		
			
			MoveData.ApplyVelocity(PlatformMovement);			
			MoveComp.Move(MoveData);
			MovingPlatform.CrumbComp.LeaveMovementCrumb();
		}
		else
		{
			FHazeActorReplicationFinalized ConsumedParams;
			MovingPlatform.CrumbComp.ConsumeCrumbTrailMovement(DeltaTime, ConsumedParams);

			FHazeFrameMovement MoveData = MoveComp.MakeFrameMovement(n"PlatformReplicatedMove");
			MoveData.ApplyDelta(ConsumedParams.DeltaTranslation);

			MoveComp.Move(MoveData);
		}
	}
}