import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;
import Cake.LevelSpecific.PlayRoom.Castle.CastleEnemy.CastleEnemy;
import Cake.LevelSpecific.PlayRoom.Castle.CastlePlayer.CastleEnemyList;
class UCastleEnemyFallingCapability : UCharacterMovementCapability
{
    default CapabilityTags.Add(n"Movement");
	default CapabilityTags.Add(n"CastleEnemyMovement");
    default CapabilityTags.Add(n"CastleEnemyFalling");
    default TickGroup = ECapabilityTickGroups::BeforeMovement;
    default TickGroupOrder = 2;
    ACastleEnemy Enemy;
	bool bCapabilitiesBlocked = false;
    UFUNCTION(BlueprintOverride)
    void Setup(FCapabilitySetupParams Params)
    {
		UCharacterMovementCapability::Setup(Params);
        Enemy = Cast<ACastleEnemy>(Owner);
    }
    UFUNCTION(BlueprintOverride)
    EHazeNetworkActivation ShouldActivate() const
    {
		if (!ShouldBeGrounded())
			return EHazeNetworkActivation::ActivateUsingCrumb; 
		else
			return EHazeNetworkActivation::DontActivate; 
    }
    UFUNCTION(BlueprintOverride)
    EHazeNetworkDeactivation ShouldDeactivate() const
    {
		if (ShouldBeGrounded())
			return EHazeNetworkDeactivation::DeactivateUsingCrumb; 
		else
			return EHazeNetworkDeactivation::DontDeactivate; 
    }
    UFUNCTION(BlueprintOverride)
    void OnActivated(FCapabilityActivationParams ActivationParams)
    {
		if (ActivationParams.IsStale())
			return;
        Owner.BlockCapabilities(n"CastleEnemyMovement", this);
        Owner.BlockCapabilities(n"CastleEnemyAI", this);
		bCapabilitiesBlocked = true;
    }
    UFUNCTION(BlueprintOverride)
    void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
    {
		if (bCapabilitiesBlocked)
		{
			Owner.UnblockCapabilities(n"CastleEnemyMovement", this);
			Owner.UnblockCapabilities(n"CastleEnemyAI", this);
			bCapabilitiesBlocked = false;
		}
    }
    UFUNCTION(BlueprintOverride)
    void TickActive(float DeltaTime)
    {
        if (!MoveComp.CanCalculateMovement())
            return;
		FHazeFrameMovement Movement = MoveComp.MakeFrameMovement(n"CastleEnemyFalling");
		if (HasControl())
		{
			Movement.ApplyAndConsumeImpulses();
			Movement.ApplyTargetRotationDelta();
			Movement.ApplyGravityAcceleration();
			Movement.ApplyActorVerticalVelocity();
			Movement.FlagToMoveWithDownImpact();
		}
		else
		{
			FHazeActorReplicationFinalized ConsumedParams;
			CrumbComp.ConsumeCrumbTrailMovement(DeltaTime, ConsumedParams);
			Movement.ApplyDeltaWithCustomVelocity(ConsumedParams.DeltaTranslation, ConsumedParams.Velocity);	
		}
		Movement.OverrideStepUpHeight(20.f);
		Movement.OverrideStepDownHeight(0.f);
		MoveComp.Move(Movement);
		if (HasControl())
			CrumbComp.LeaveMovementCrumb();
		// Check if we are inside any kill volumes while we're falling
		if (IsInCastleEnemyKillVolume(Enemy.ActorLocation))
		{
			Enemy.Kill();
		}
		Enemy.SendMovementAnimationRequest(Movement, n"CastleEnemyFalling", NAME_None);
    }
};