import Cake.LevelSpecific.PlayRoom.Castle.Dungeon.Crusher.CastleCrusher;
import Cake.LevelSpecific.PlayRoom.Castle.CastlePlayer.CastleComponent;

class UCastleCrusherCrushPlayersCapability : UHazeCapability
{
	default CapabilityTags.Add(n"Castle");
	default CapabilityTags.Add(n"Crusher");
	default CapabilityTags.Add(n"Crush");

	default CapabilityDebugCategory = n"Castle";
	
	default TickGroup = ECapabilityTickGroups::ActionMovement;
	default TickGroupOrder = 90;

	ACastleCrusher Crusher;

	bool bCompletedMove = false;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Crusher = Cast<ACastleCrusher>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{

    }

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (!Crusher.bShouldCrushPlayers)
        	return EHazeNetworkActivation::DontActivate;

		if (Crusher.MoveToCrushActor == nullptr)
        	return EHazeNetworkActivation::DontActivate;

        return EHazeNetworkActivation::ActivateFromControl;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (bCompletedMove || DistanceToTarget <= 0.f)
        	return EHazeNetworkDeactivation::DeactivateFromControl;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Crusher.BlockCapabilities(n"Movement", this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Crusher.UnblockCapabilities(n"Movement", this);

		for (AHazePlayerCharacter Player : Game::GetPlayers())
		{
			UCastleComponent CastleComp = UCastleComponent::GetOrCreate(Player);
			KillPlayer(Player);
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		Crusher.Speed = 400.f;
		float Delta = Crusher.Speed * DeltaTime;

		if (DistanceToTarget < Delta)
		{
			Delta = DistanceToTarget;
			bCompletedMove = true;
		}

		Crusher.AddActorWorldOffset(Crusher.ActorForwardVector * Delta);
	}

	float GetDistanceToTarget() const property
	{
		FVector ToMoveTo = Crusher.MoveToCrushActor.ActorLocation - Owner.ActorLocation;
		return ToMoveTo.DotProduct(Owner.ActorForwardVector);
	}
}