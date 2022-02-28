import Cake.LevelSpecific.SnowGlobe.MagnetHarpoon.MagnetFishActor;
import Vino.BouncePad.BouncePadResponseComponent;
import Vino.Movement.Components.ImpactCallback.ActorImpactedCallbackGlobalBindFunctions;
import Vino.Movement.Capabilities.GroundPound.CharacterGroundPoundFallCapabilty;

event void FOnFishEaten();
event void FOnSealBouncedOn(AHazePlayerCharacter Player);

class AHarpoonHarpSeal : AHazeActor
{
	FOnFishEaten OnFishEaten;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent EatLoc;

	UPROPERTY(DefaultComponent, Attach = Root)
	UHazeSkeletalMeshComponentBase SkelMeshComp;

	UPROPERTY(DefaultComponent)
	UHazeDisableComponent HazeDisableComp;
	
	UPROPERTY(DefaultComponent)
	UBouncePadResponseComponent BouncePadComp;

    UPROPERTY()
    FOnSealBouncedOn OnBouncedOn;

	private AMagnetFishActor MagnetFish;

    UPROPERTY(Category = "Bounce Properties")
    float VerticalVelocity = 1000.f;

    UPROPERTY(Category = "Bounce Properties")
    float HorizontalVelocityModifier = 0.5f;

    UPROPERTY(Category = "Bounce Properties")
    float MaximumHorizontalVelocity = 500.f;

    UPROPERTY(EditDefaultsOnly, Category = "Bounce Properties")
    TSubclassOf<UHazeCapability> BouncePadCapabilityClass;
	default BouncePadCapabilityClass = Asset("/Game/Blueprints/LevelMechanics/YBP_CharacterBouncePad.YBP_CharacterBouncePad_C");

	UPROPERTY(Category = "EatDistance")
	float EatDistance = 150.f;

	UPROPERTY(Category = "EatDistance")
	float FishDistance;

	UPROPERTY()
	bool bPlayerHasFish;

	UPROPERTY()
	FTimerHandle TimerHandle;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		FActorImpactedByPlayerDelegate OnPlayerLanded;
        OnPlayerLanded.BindUFunction(this, n"PlayerLandedOnBouncePad");
        BindOnDownImpactedByPlayer(this, OnPlayerLanded);
	}

	UFUNCTION()
	void ClearPreviousFish()
	{
		if (MagnetFish != nullptr)
		{
			System::ClearAndInvalidateTimerHandle(TimerHandle);
			DeactivateFish();
		}
	}

	//Whoever tells to eat the fish, needs to activate readyfornext fish with a net function
	UFUNCTION()
	void EatFish(AMagnetFishActor InMagnetFish)
	{
		MagnetFish = InMagnetFish;
		MagnetFish.RootComponent.AttachToComponent(SkelMeshComp, n"Align", EAttachmentRule::SnapToTarget, EAttachmentRule::SnapToTarget, EAttachmentRule::KeepWorld, false);
		MagnetFish.FishBeingEaten();

		SetAnimBoolParam(n"ReadyForFish", false);
		SetAnimBoolParam(n"EatFish", true);

		TimerHandle	= System::SetTimer(this, n"DeactivateFish", 4.5f, false);
	
		OnFishEaten.Broadcast();
	}

	UFUNCTION()
	void DeactivateFish()
	{
		MagnetFish.DeactivateFish();
		MagnetFish = nullptr;
		SetAnimBoolParam(n"EatFish", false);
	}

    UFUNCTION()
    void PlayerLandedOnBouncePad(AHazePlayerCharacter Player, FHitResult HitResult)
    {
        if (Player.HasControl())
        {
			bool bGroundPounded = false;
			
			if (Player.IsAnyCapabilityActive(UCharacterGroundPoundFallCapability::StaticClass()))
				bGroundPounded = true;
				
			Player.SetCapabilityAttributeValue(n"VerticalVelocity", VerticalVelocity);
			Player.SetCapabilityAttributeValue(n"HorizontalVelocityModifier", HorizontalVelocityModifier);
			Player.SetCapabilityActionState(n"Bouncing", EHazeActionState::Active);
        }
			
		SetOnBounceSeal();
    }

	UFUNCTION()
	void SetOnHitSeal()
	{
		SetAnimBoolParam(n"ClawHit", true);
	}

	UFUNCTION()
	void SetOnBounceSeal()
	{
		SetAnimBoolParam(n"BouncedOn", true);
	}
}