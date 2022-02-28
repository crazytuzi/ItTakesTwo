import Peanuts.Audio.AudioStatics;
import Vino.Movement.Components.MovementComponent;
import Cake.LevelSpecific.Garden.ControllablePlants.Beanstalk.Beanstalk;
import Cake.LevelSpecific.Garden.ControllablePlants.Beanstalk.BeanstalkTags;
import Vino.Audio.Capabilities.AudioTags;

class UBeanstalkLeafJumpingAudioCapability : UHazeCapability
{
	ABeanstalk BeanstalkOwner;
	AHazePlayerCharacter PlayerOwner;
	UPlayerHazeAkComponent PlayerHazeAkComp;
	UHazeMovementComponent MoveComp;

	UPROPERTY()
	UAkAudioEvent JumpOnEvent;

	UPROPERTY()
	UAkAudioEvent JumpOffEvent;

	bool bCanTriggerLanding = false;
	bool bHasLandedOnLeaf = false;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		BeanstalkOwner = Cast<ABeanstalk>(Owner);
		PlayerOwner = Game::GetMay();
		PlayerHazeAkComp = UPlayerHazeAkComponent::Get(PlayerOwner);
		MoveComp = UHazeMovementComponent::Get(PlayerOwner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!BeanstalkOwner.bBeanstalkActive)
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

		UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(BeanstalkOwner.bBeanstalkActive)
			return EHazeNetworkDeactivation::DontDeactivate;
		
		return EHazeNetworkDeactivation::DeactivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(!MoveComp.IsGrounded())
			bCanTriggerLanding = true;

		ABeanstalkLeafPair DownHitLeafActor = Cast<ABeanstalkLeafPair>(MoveComp.DownHit.Actor);		

		if(DownHitLeafActor != nullptr && bCanTriggerLanding)
		{
			PlayerHazeAkComp.HazePostEvent(JumpOnEvent);
			bCanTriggerLanding = false;
			bHasLandedOnLeaf = true;		
		}

		if(bHasLandedOnLeaf && DownHitLeafActor == nullptr)
		{			
			PlayerHazeAkComp.HazePostEvent(JumpOffEvent);
			bHasLandedOnLeaf = false;			
		}
	}

}