import Cake.LevelSpecific.Music.NightClub.CharacterDiscoBallMovementComponent;
import Cake.LevelSpecific.Music.NightClub.DiscoBallMovementSettings;
import Vino.Checkpoints.Statics.DeathStatics;
import Vino.Movement.Components.MovementComponent;

class UDiscoBallOutOfBoundsCapability : UHazeCapability
{
	UCharacterDiscoBallMovementComponent DiscoComp;
	FDiscoBallMovementSettings MoveSettings;
	AHazePlayerCharacter Player;
	UHazeMovementComponent MoveComp;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		DiscoComp = UCharacterDiscoBallMovementComponent::Get(Owner);
		MoveComp = UHazeMovementComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate()const
	{
		FVector DistanceBetweenBallAndPlayer = DiscoComp.DiscoBall.ActorLocation - Player.ActorLocation;
		
		if (MoveComp.IsAirborne() && DistanceBetweenBallAndPlayer.Size() <= 6000.f)
		{
			return EHazeNetworkActivation::DontActivate;
		}
				
		if (!IsPlayerOutsideBounds())
		{
			return EHazeNetworkActivation::DontActivate;
		}

		return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate()const
	{
		return EHazeNetworkDeactivation::DeactivateLocal;
	}


	bool IsPlayerOutsideBounds()const
	{
		if (DiscoComp.DistanceFromCenter() > MoveSettings.AllowedDistanceFromCenter)
		{
			return true;
		}
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams)
	{
		KillPlayer(Player, DiscoComp.DeathFX);
	}
	
}