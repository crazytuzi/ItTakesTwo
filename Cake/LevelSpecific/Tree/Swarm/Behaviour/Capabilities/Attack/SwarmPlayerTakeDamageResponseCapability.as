
import Cake.LevelSpecific.Tree.Swarm.SwarmActor;
import Cake.LevelSpecific.Tree.Swarm.Behaviour.Capabilities.Attack.SwarmPlayerTakeDamageEffect;

import Vino.Movement.MovementSystemTags;
import Vino.Movement.Components.MovementComponent;
import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;
import Vino.Movement.Capabilities.KnockDown.CharacterKnockDownCapability;

import Vino.PlayerHealth.PlayerHealthStatics;

//class USwarmPlayerTakeDamageResponseCapability : UCharacterMovementCapability
class USwarmPlayerTakeDamageResponseCapability : UHazeCapability
{
	default CapabilityTags.Add(n"PlayerTakeDamage");
	default CapabilityTags.Add(n"SwarmPlayerTakeDamage");
	default CapabilityTags.Add(n"SwarmPlayerTakeDamageResponse");

	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = ECapabilityTickGroups::ActionMovement;
	default TickGroupOrder = 101; // After regular knockdown, before spline slide knockdown

	// How often we can take damage
	float TakeDamageCooldown = 1.5f;

	// Settings
	//////////////////////////////////////////////////////////////////////////
	// Transient

	float TakeDamageTimeStamp = 0.f;
	ASwarmActor SwarmAttacker = nullptr;
	UHazeMovementComponent MoveComp;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		MoveComp = UHazeMovementComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!WasActionStarted(n"SwarmAttack"))
			return EHazeNetworkActivation::DontActivate;

		const float TimeSinceDamageTaken = Time::GetGameTimeSince(TakeDamageTimeStamp); 
		if (TimeSinceDamageTaken <= TakeDamageCooldown)
			return EHazeNetworkActivation::DontActivate;

		if(!BlackboardContainsSwarm())
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateFromControl;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		return EHazeNetworkDeactivation::DeactivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& OutParams)
	{
		OutParams.AddObject(n"SwarmAttacker", ConsumeSwarmFromBlackboard());
		OutParams.AddValue(n"SwarmAttackDamage", GetAttributeValue(n"SwarmAttackDamage"));
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Owner.BlockCapabilities(MovementSystemTags::Dash, this);
		Owner.BlockCapabilities(n"Weapon", this);

		SwarmAttacker = Cast<ASwarmActor>(ActivationParams.GetObject(n"SwarmAttacker")); 

		// This might happen in editor when restarting progress points
		if(SwarmAttacker == nullptr)
			return;

		// handle damage override
		float SwarmAttackDamage = ActivationParams.GetValue(n"SwarmAttackDamage");
		if(SwarmAttackDamage == 0.f)
			SwarmAttackDamage = SwarmAttacker.VictimComp.AttackDamage;

		DamagePlayerHealth(
			Cast<AHazePlayerCharacter>(Owner),
			SwarmAttackDamage,
			TSubclassOf<UPlayerDamageEffect>(USwarmPlayerTakeDamageEffect::StaticClass())
		);

 		ApplyCollisionImpulse();

		// Play knockdown animation as long as we aren't grinding
		UHazeSplineFollowComponent FollowComp = UHazeSplineFollowComponent::Get(Owner);
		if(FollowComp.HasActiveSpline() == false)
			Owner.AddCapability(UCharacterKnockDownCapability::StaticClass());

		SwarmAttacker = nullptr;
		TakeDamageTimeStamp = Time::GetGameTimeSeconds();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Owner.UnblockCapabilities(MovementSystemTags::Dash, this);
		Owner.UnblockCapabilities(n"Weapon", this);
	}

	void ApplyCollisionImpulse()
	{

		FSwarmParticle ClosestParticle;
		const bool bParticleFound = SwarmAttacker.GetParticleClosestToLocation( Owner.GetActorCenterLocation(), ClosestParticle);
		if (!bParticleFound)
			return;

		FVector AttackDirection = SwarmAttacker.GetActorForwardVector();
		FVector ToPlayerNormalizedXY = Owner.GetActorCenterLocation() - ClosestParticle.CurrentTransform.GetLocation();
		ToPlayerNormalizedXY = ToPlayerNormalizedXY.VectorPlaneProject(FVector::UpVector);
		ToPlayerNormalizedXY.Normalize();
		const bool bMovingTowardsPlayer = ClosestParticle.Velocity.DotProduct(ToPlayerNormalizedXY) >= 0.f;
		if (bMovingTowardsPlayer)
			AttackDirection = ToPlayerNormalizedXY;

		// Include player velocity in the impulse because that 
		// gets zeroed out in CharacterKnockdownCapability
		FVector ImpulseFromSwarm = MoveComp.GetVelocity();

		// Just keep player velocity if we take damage while in air.
		auto PlayerMoveComp = UHazeBaseMovementComponent::Get(Owner);
		if(PlayerMoveComp.IsGrounded())
		{
			const FVector Magnitude = SwarmAttacker.VictimComp.KnockdownMagnitude;
			const FVector ExtraImpulseForward = AttackDirection * Magnitude.X;
			const FVector ExtraImpulseRight = FVector::UpVector.CrossProduct(AttackDirection).GetSafeNormal() * Magnitude.Y;
			const FVector UpImpulse = FVector::UpVector * Magnitude.Z;
			ImpulseFromSwarm += UpImpulse;
			ImpulseFromSwarm += ExtraImpulseForward;
			ImpulseFromSwarm += ExtraImpulseRight;
		}

		Owner.SetCapabilityAttributeVector(n"KnockdownDirection", ImpulseFromSwarm);
		Owner.SetCapabilityActionState(n"KnockDown", EHazeActionState::Active);
	}

	bool BlackboardContainsSwarm() const
	{
		return GetAttributeObject(n"SwarmAttacker") != nullptr;
	}

	ASwarmActor ConsumeSwarmFromBlackboard()
	{
		UObject OutObject;
		ConsumeAttribute(n"SwarmAttacker", OutObject);
		return Cast<ASwarmActor>(OutObject);
	}

}













