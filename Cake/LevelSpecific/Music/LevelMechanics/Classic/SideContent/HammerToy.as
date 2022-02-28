import Vino.PlayerHealth.PlayerHealthStatics;
import Vino.Buttons.GroundPoundButton;

class AHammerToy : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)	
	USceneComponent RootComp;
	UPROPERTY(DefaultComponent, Attach = RootComp)	
	USceneComponent HammerSceneComp;
	UPROPERTY(DefaultComponent, Attach = HammerSceneComp)	
	UStaticMeshComponent MeshBody;
	UPROPERTY(DefaultComponent, Attach = MeshBody)
	UBoxComponent HammerCollider;
	UPROPERTY(DefaultComponent, Attach = RootComp)	
	UStaticMeshComponent MeshBase;
	UPROPERTY(DefaultComponent)
	UHazeDisableComponent DisableComponent;
	default DisableComponent.bAutoDisable = true;
	default DisableComponent.AutoDisableRange = 20000.f;
	UPROPERTY()
	TSubclassOf<UPlayerDeathEffect> DeathEffect;

	UPROPERTY()
	AGroundPoundButton GroundPoundButton;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent HitAudioEvent;

	FHazeAcceleratedFloat AcceleratedFloat;
	float TargetRotation = -75;
	bool bIsRetracting = true;
	float ExtraRotation;

	int PlayersStandingOnbutton = 0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		HammerCollider.OnComponentBeginOverlap.AddUFunction(this, n"OnComponentBeginOverlap");

		FActorImpactedByPlayerDelegate ImpactDelegate;
		ImpactDelegate.BindUFunction(this, n"LandOnPlatform");
		BindOnDownImpactedByPlayer(GroundPoundButton, ImpactDelegate);
		FActorNoLongerImpactingByPlayerDelegate NoImpactDelegate;
		NoImpactDelegate.BindUFunction(this, n"LeavePlatform");
		BindOnDownImpactEndedByPlayer(GroundPoundButton, NoImpactDelegate);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(bIsRetracting == false)
		{
			if(AcceleratedFloat.Value > -74)
			{
				AcceleratedFloat.SpringTo(TargetRotation, 500, 1, DeltaSeconds);
				MeshBody.SetRelativeRotation(FRotator(AcceleratedFloat.Value, 0, 0));
			}
		}
		else
		{
			AcceleratedFloat.SpringTo(0 + ExtraRotation, 250, 1, DeltaSeconds);
			MeshBody.SetRelativeRotation(FRotator(AcceleratedFloat.Value, 0, 0));
		}

		if(AcceleratedFloat.Value <= -71)
		{
			bIsRetracting = true;
		}
	}


	UFUNCTION(NotBlueprintCallable)
    void LandOnPlatform(AHazePlayerCharacter Player, FHitResult Hit)
    {
		PlayersStandingOnbutton ++;
		if(PlayersStandingOnbutton == 1)
		{
			ExtraRotation = -5;
		}	
		else if(PlayersStandingOnbutton == 2)
		{
			ExtraRotation = -10;
		}
    }
    UFUNCTION(NotBlueprintCallable)
    void LeavePlatform(AHazePlayerCharacter Player)
    {
		PlayersStandingOnbutton --;

		if(PlayersStandingOnbutton == 0)
		{
			ExtraRotation = 0;
		}	
		else if(PlayersStandingOnbutton == 1)
		{
			ExtraRotation = -5;
		}
    }

	UFUNCTION()
	void ActivateHammer()
	{
		bIsRetracting = false;
		UHazeAkComponent::HazePostEventFireForget(HitAudioEvent, GetActorTransform());
	}


	UFUNCTION()
	void OnComponentBeginOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor, 
	UPrimitiveComponent OtherComponent, int OtherBodyIndex, bool bFromSweep, FHitResult& Hit)
	{
		if(bIsRetracting)
			return;

		if(OtherActor == Game::GetCody())
		{
			if(Game::GetCody().HasControl())
			{
				Game::GetCody().KillPlayer(DeathEffect);
			}
		}
		if(OtherActor == Game::GetMay())
		{
			if(Game::GetMay().HasControl())
			{
				Game::GetMay().KillPlayer(DeathEffect);
			}
		}
	}
}

