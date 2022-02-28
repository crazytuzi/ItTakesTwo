import Vino.Interactions.InteractionComponent;
import Vino.PlayerHealth.PlayerHealthStatics;

class AClassicHatchSlide : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;
	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent RootCompHatchLid;
	UPROPERTY(DefaultComponent, Attach = RootCompHatchLid)
	UStaticMeshComponent HatchLid;
	UPROPERTY(DefaultComponent, Attach = HatchLid)
	UHazeLazyPlayerOverlapComponent DeathTrigger;
	UPROPERTY(DefaultComponent, Attach = HatchLid)
	UHazeLazyPlayerOverlapComponent DeathTriggerTwo;
	UPROPERTY(DefaultComponent, Attach = HatchLid)
	UHazeLazyPlayerOverlapComponent DeathTriggerThree;
	UPROPERTY(DefaultComponent, Attach = HatchLid)
	UHazeLazyPlayerOverlapComponent DeathTriggerFour;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UPlayerDeathEffect> DeathEffect;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent HatchOpenAudioEvent;

	FHazeAcceleratedFloat AcceleratedFloat;
	bool bAllowTick = false;
	bool bCanKillPlayers = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		DeathTrigger.OnPlayerBeginOverlap.AddUFunction(this, n"EnterDeathTrigger");
		DeathTriggerTwo.OnPlayerBeginOverlap.AddUFunction(this, n"EnterDeathTrigger");
		DeathTriggerThree.OnPlayerBeginOverlap.AddUFunction(this, n"EnterDeathTrigger");
		DeathTriggerFour.OnPlayerBeginOverlap.AddUFunction(this, n"EnterDeathTrigger");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
	//	PrintToScreen("bCanKillPlayers " + bCanKillPlayers);
		if(!bAllowTick)
			return;

		AcceleratedFloat.SpringTo(185, 15, 0.8, DeltaSeconds);
		FRotator RelativeRotationButton;
		RelativeRotationButton.Roll = AcceleratedFloat.Value;
		HatchLid.SetRelativeRotation(FRotator(0,0, RelativeRotationButton.Roll));

		if(AcceleratedFloat.Value >= 185)
		{
			bCanKillPlayers = false;
		}
	}

	UFUNCTION(NotBlueprintCallable)
	void EnterDeathTrigger(AHazePlayerCharacter Player)
	{
	 	if(bCanKillPlayers == true)
	 	{
			if(Player.HasControl())
				Player.KillPlayer(DeathEffect);
		}
	}

	UFUNCTION()
	void OpenHatch()
	{
		bAllowTick = true;
		bCanKillPlayers = true;
		System::SetTimer(this, n"AutoDisable", 10.f, false);
		UHazeAkComponent::HazePostEventFireForget(HatchOpenAudioEvent, this.GetActorTransform());


		if(Game::GetCody().HasControl())
		{
			if(DeathTrigger.IsPlayerOverlapping(Game::GetCody()) or DeathTriggerTwo.IsPlayerOverlapping(Game::GetCody()) 
			or DeathTriggerThree.IsPlayerOverlapping(Game::GetCody()) or DeathTriggerFour.IsPlayerOverlapping(Game::GetCody()))
			{
				Game::GetCody().KillPlayer(DeathEffect);
			}
		}

		if(Game::GetMay().HasControl())
		{
			if(DeathTrigger.IsPlayerOverlapping(Game::GetMay()) or DeathTriggerTwo.IsPlayerOverlapping(Game::GetMay()) 
			or DeathTriggerThree.IsPlayerOverlapping(Game::GetMay()) or DeathTriggerFour.IsPlayerOverlapping(Game::GetMay()))
			{
				Game::GetMay().KillPlayer(DeathEffect);
			}
		}
	}

	UFUNCTION()
	void AutoDisable()
	{
		bAllowTick = false;
	}
}

