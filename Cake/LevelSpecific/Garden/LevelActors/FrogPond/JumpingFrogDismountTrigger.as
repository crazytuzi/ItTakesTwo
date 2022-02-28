import Cake.LevelSpecific.Garden.JumpingFrog.JumpingFrog;
import Vino.Tutorial.TutorialStatics;
import Cake.LevelSpecific.Garden.JumpingFrog.JumpingFrogPlayerRideComponent;
import Peanuts.Triggers.ActorTrigger;

class AJUmpingFrogDismountTrigger : AHazeActor
{

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComponent)
	UBoxComponent TriggerComp;

	UPROPERTY(Category = "Settings")
	bool bActiveForMay = true;

	UPROPERTY(Category = "Settings")
	bool bActiveForCody = true;

	UPROPERTY(Category = "Settings")
	bool bDisableRemountMay = false;

	UPROPERTY(Category = "Settings")
	bool bDisableRemountCody = false;

	UPROPERTY(Category = "Settings")
	FText DismountText;

	UPROPERTY(Category = "Settings")
	AActorTrigger ExternalActorTrigger;

	bool bShouldTriggerMayVO = false;
	bool bShouldTriggerCodyVO = false;
	bool bUseExternalTrigger = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		//If Custom collider is referenced.
		if(ExternalActorTrigger == nullptr)
		{
			TriggerComp.OnComponentBeginOverlap.AddUFunction(this, n"OnBeginOverlap");
			TriggerComp.OnComponentEndOverlap.AddUFunction(this, n"OnEndOverlap");
		}
		else
		{
			ExternalActorTrigger.OnActorBeginOverlap.AddUFunction(this, n"OnBeginExternalOverlap");
			ExternalActorTrigger.OnActorEndOverlap.AddUFunction(this, n"OnEndExternalOverlap");

			TriggerComp.SetCollisionEnabled(ECollisionEnabled::NoCollision);
		}
	}

	UFUNCTION()
	void SetShouldTriggerVOStates(bool ShouldTriggerMay, bool bShouldTriggerCody)
	{
		bShouldTriggerMayVO = ShouldTriggerMay;
		bShouldTriggerCodyVO = bShouldTriggerCody;
	}

	UFUNCTION()
    void OnBeginOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
		UPrimitiveComponent OtherComponent, int OtherBodyIndex,
		bool bFromSweep, FHitResult& Hit)
    {
        AJumpingFrog Frog = Cast<AJumpingFrog>(OtherActor);
        if (Frog == nullptr)
		{
			AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
			if(Player == nullptr)
				return;

			UJumpingFrogPlayerRideComponent PlayerFrogComp = UJumpingFrogPlayerRideComponent::Get(Player);

			if(PlayerFrogComp == nullptr)
				return;

			if(PlayerFrogComp.Frog == nullptr)
				return;
				
			Frog = PlayerFrogComp.Frog;
		}

		if(Frog.MountedPlayer.IsCody())
		{
			if(bActiveForCody)
			{
				if(bShouldTriggerCodyVO)
				{
					Frog.MountedPlayer.SetCapabilityActionState(n"TriggerCodyDismountVO", EHazeActionState::Active);
				}

				Frog.MountedPlayer.SetCapabilityActionState(n"AllowDismount", EHazeActionState::Active);

				if(bDisableRemountCody)
					Frog.InteractionPoint.Disable(n"ReachedEnd");
			}
		}
		else if(Frog.MountedPlayer.IsMay())
		{
			if(bActiveForMay)
			{
				if(bShouldTriggerMayVO)
				{
					Frog.MountedPlayer.SetCapabilityActionState(n"TriggerMayDismountVO", EHazeActionState::Active);
				}

				Frog.MountedPlayer.SetCapabilityActionState(n"AllowDismount", EHazeActionState::Active);

				if(bDisableRemountMay)
					Frog.InteractionPoint.Disable(n"ReachedEnd");
			}
		}
    }

	UFUNCTION()
	void OnEndOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor, UPrimitiveComponent OtherComponent, int OtherBodyIndex)
	{
        AJumpingFrog Frog = Cast<AJumpingFrog>(OtherActor);
        if (Frog == nullptr)
		{
			AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
			if(Player == nullptr)
				return;

			UJumpingFrogPlayerRideComponent PlayerFrogComp = UJumpingFrogPlayerRideComponent::Get(Player);

			if(PlayerFrogComp == nullptr)
				return;

			if(PlayerFrogComp.Frog == nullptr)
				return;
				
			Frog = PlayerFrogComp.Frog;
		}

		if(Frog.MountedPlayer == nullptr)
			return;

		if(Frog.MountedPlayer.IsCody())
		{
			if(bActiveForCody)
			{
				Frog.MountedPlayer.SetCapabilityActionState(n"AllowDismount", EHazeActionState::Inactive);
			}
		}
		else if(Frog.MountedPlayer.IsMay())
		{
			if(bActiveForMay)
			{
				Frog.MountedPlayer.SetCapabilityActionState(n"AllowDismount", EHazeActionState::Inactive);
			}
		}
	}

	//If using Collider other then inherited.
	UFUNCTION()
	void OnBeginExternalOverlap(AActor OverlappedActor, AActor OtherActor)
	{
        AJumpingFrog Frog = Cast<AJumpingFrog>(OtherActor);
        if (Frog == nullptr)
		{
			AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
			if(Player == nullptr)
				return;

			UJumpingFrogPlayerRideComponent PlayerFrogComp = UJumpingFrogPlayerRideComponent::Get(Player);

			if(PlayerFrogComp == nullptr)
				return;

			if(PlayerFrogComp.Frog == nullptr)
				return;
				
			Frog = PlayerFrogComp.Frog;
		}

		if(Frog.MountedPlayer.IsCody())
		{
			if(bActiveForCody)
			{
				if(bShouldTriggerCodyVO)
				{
					Frog.MountedPlayer.SetCapabilityActionState(n"TriggerCodyDismountVO", EHazeActionState::Active);
				}

				Frog.MountedPlayer.SetCapabilityActionState(n"AllowDismount", EHazeActionState::Active);

				if(bDisableRemountCody)
					Frog.InteractionPoint.Disable(n"ReachedEnd");
			}
		}
		else if(Frog.MountedPlayer.IsMay())
		{
			if(bActiveForMay)
			{
				if(bShouldTriggerMayVO)
				{
					Frog.MountedPlayer.SetCapabilityActionState(n"TriggerMayDismountVO", EHazeActionState::Active);
				}

				Frog.MountedPlayer.SetCapabilityActionState(n"AllowDismount", EHazeActionState::Active);

				if(bDisableRemountMay)
					Frog.InteractionPoint.Disable(n"ReachedEnd");
			}
		}
	}

	UFUNCTION()
	void OnEndExternalOverlap(AActor OverlappedActor, AActor OtherActor)
	{
        AJumpingFrog Frog = Cast<AJumpingFrog>(OtherActor);
        if (Frog == nullptr)
		{
			AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
			if(Player == nullptr)
				return;

			UJumpingFrogPlayerRideComponent PlayerFrogComp = UJumpingFrogPlayerRideComponent::Get(Player);

			if(PlayerFrogComp == nullptr)
				return;

			if(PlayerFrogComp.Frog == nullptr)
				return;
				
			Frog = PlayerFrogComp.Frog;
		}

		if(Frog.MountedPlayer == nullptr)
			return;

		if(Frog.MountedPlayer.IsCody())
		{
			if(bActiveForCody)
			{
				Frog.MountedPlayer.SetCapabilityActionState(n"AllowDismount", EHazeActionState::Inactive);
			}
		}
		else if(Frog.MountedPlayer.IsMay())
		{
			if(bActiveForMay)
			{
				Frog.MountedPlayer.SetCapabilityActionState(n"AllowDismount", EHazeActionState::Inactive);
			}
		}
	}
}