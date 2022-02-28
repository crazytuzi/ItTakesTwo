import Vino.Pickups.PickupActor;
import Cake.LevelSpecific.PlayRoom.SpaceStation.ChangeSize.CharacterChangeSizeComponent;
import Cake.LevelSpecific.PlayRoom.SpaceStation.SpaceConductorIndicatorStar;
import Cake.LevelSpecific.PlayRoom.VOBanks.SpacestationVOBank;

UCLASS(Abstract)
class ASpaceConductor : APickupActor
{
	UPROPERTY(DefaultComponent)
	USceneComponent ConnectPoint;

	UPROPERTY(DefaultComponent)
	UCharacterChangeSizeCallbackComponent ChangeSizeCallbackComp;

	UPROPERTY(DefaultComponent)
	UHazeDisableComponent DisableComponent;
	default DisableComponent.bAutoDisable = true;
	default DisableComponent.bRenderWhileDisabled = true;
	default DisableComponent.AutoDisableRange = 10000.f;

	UPROPERTY(EditDefaultsOnly)
	USpacestationVOBank VOBank;

	UPROPERTY()
	bool bPlayPickupBark = true;

	UPROPERTY()
	ASpaceConductorIndicatorStar ConnectedStar;

	UPROPERTY()
	bool bIsConnected = false;

	UPROPERTY(NotVisible)
	bool bHasStarted = false;

	bool bReadyToPlay = false;
	bool bRunTimer = true;
	bool bPendingAwake = true;

	float CooldownTimer = 0.f;

	UPROPERTY(NotVisible)
	float CooldownTime = 0.f;

	// Set by ConductorStartPoint for tracking
	bool bChainMarked = false; 

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		ChangeSizeCallbackComp.OnCharacterChangedSize.AddUFunction(this, n"ChangedSize");

		if (ConnectedStar != nullptr)
			OnPickedUpEvent.AddUFunction(this, n"PickedUp");
	}

	UFUNCTION(NotBlueprintCallable)
	void PickedUp(AHazePlayerCharacter Player, APickupActor Actor)
	{
		OnPickedUpEvent.Unbind(this, n"PickedUp");
		ConnectedStar.SetActiveStatus(false);

		if (bPlayPickupBark)
		{
			bPlayPickupBark = false;
			FName BarkEventName = Player.IsMay() ? n"FoghornDBPlayRoomSpaceStationConductorPickupMay" : n"FoghornDBPlayRoomSpaceStationConductorPickupCody";
			VOBank.PlayFoghornVOBankEvent(BarkEventName);
		}
	}

	UFUNCTION()
	void DisablePickupBark()
	{
		bPlayPickupBark = false;
	}

	UFUNCTION()
	void DeactivateConnectedStar()
	{
		if (ConnectedStar != nullptr)
			ConnectedStar.SetActiveStatus(false);
	}

	UFUNCTION(NotBlueprintCallable)
	void ChangedSize(FChangeSizeEventTempFix Size)
	{
		if (Size.NewSize == ECharacterSize::Small || Size.NewSize == ECharacterSize::Large)
			InteractionComponent.DisableForPlayer(Game::GetCody(), n"Size");
		else
			InteractionComponent.EnableForPlayer(Game::GetCody(), n"Size");
	}

	UFUNCTION()
	void PlayConductorSound(UAkAudioEvent Event)
	{
		if(bReadyToPlay && !bPendingAwake)
		{
			UHazeAkComponent::HazePostEventFireForget(Event, GetActorTransform());			
		}
	}
	
	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if(bPendingAwake)
		{
			CooldownTimer += DeltaTime;

			if(CooldownTimer >= 1.f)
			{
				bReadyToPlay = true;
				bPendingAwake = false;
			}
		}

		if(CooldownTime != 0.f)
		{
			if(bRunTimer)
			{
				CooldownTimer += DeltaTime;

				if(CooldownTimer >= CooldownTime)
				{
					bReadyToPlay = true;
					bRunTimer = false;
					CooldownTimer = 0.f;
				}
			}
		}
		else
		{
			bReadyToPlay = true;
		}

		if (HoldingPlayer != nullptr && bIsConnected)
			HoldingPlayer.SetFrameForceFeedback(0.05f, 0.0f);
	}
}