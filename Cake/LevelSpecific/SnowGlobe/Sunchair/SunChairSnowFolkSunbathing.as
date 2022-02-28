import Cake.LevelSpecific.SnowGlobe.SnowballFight.SnowballFightResponseComponent;
import Vino.BouncePad.BouncePadResponseComponent;
import Vino.Movement.Components.ImpactCallback.ActorImpactedCallbackGlobalBindFunctions;
import Vino.Movement.Capabilities.GroundPound.CharacterGroundPoundFallCapabilty;

class SunChairSnowFolkSunbathing : AHazeActor
{
	// Animations
    UPROPERTY()
    FHazePlaySequenceData Mh;

	UPROPERTY()
    FHazePlaySequenceData HitReaction;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UCapsuleComponent CapsuleComp;
	default CapsuleComp.SetCollisionResponseToAllChannels(ECollisionResponse::ECR_Block);
	// default CapsuleComp.SetRelativeRotation(FRotator(108,0,0));
	// default CapsuleComp.SetRelativeLocation(FVector(0,0,50));

	UPROPERTY(DefaultComponent, Attach = Root)	
	UHazeCharacterSkeletalMeshComponent SkeletalMesh;

	//TODO Snowball Hit Reaction
	UPROPERTY(DefaultComponent)	
	USnowballFightResponseComponent SnowballFightResponseComponent;

	UPROPERTY(DefaultComponent)
	UBouncePadResponseComponent BouncePadResponseComp;

    UPROPERTY(Category = "Bounce Properties")
    float VerticalVelocity = 1500.f;

    UPROPERTY(Category = "Bounce Properties")
    float HorizontalVelocityModifier = 0.5f;

    UPROPERTY(Category = "Bounce Properties")
    float MaximumHorizontalVelocity = 500.f;

	UPROPERTY(DefaultComponent)
	UHazeAkComponent HazeAkComp;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent BounceAudioEvent;

	float Timer = 1.5f;

	UPROPERTY()
	bool bCanTriggerSnowballhit;

	UPROPERTY()
	FVector StartingScale;

	UFUNCTION(BlueprintOverride) 
	void BeginPlay()
	{
		SnowballFightResponseComponent.OnSnowballHit.AddUFunction(this, n"HitBySnowBall");	

        FActorImpactedByPlayerDelegate OnPlayerLanded;
        OnPlayerLanded.BindUFunction(this, n"PlayerLandedOnBouncePad");
        BindOnDownImpactedByPlayer(this, OnPlayerLanded);

		StartingScale = SkeletalMesh.GetWorldScale();
	}

    UPROPERTY()
	float CullDistanceMultiplier = 1.0f;

	UFUNCTION(BlueprintOverride)
    void ConstructionScript()
    {
		SkeletalMesh.SetCullDistance(Editor::GetDefaultCullingDistance(SkeletalMesh) * CullDistanceMultiplier);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (bCanTriggerSnowballhit)
		{
			Timer -= DeltaTime;

			if (Timer <= 0.f)
				bCanTriggerSnowballhit = false;
		}
	}

	UFUNCTION()
	void HitBySnowBall(AActor ProjectileOwner, FHitResult Hit, FVector HitVelocity)
	{
		SkeletalMesh.SetAnimBoolParam(n"bHitBySnowball", true);

		if (!bCanTriggerSnowballhit)
		{
			bCanTriggerSnowballhit = true;
			Timer = 2.f;
		}
	}

	UFUNCTION()
    void PlayerLandedOnBouncePad(AHazePlayerCharacter Player, FHitResult HitResult)
    {
		bool bGroundPounded = false;

		Player.PlayerHazeAkComp.HazePostEvent(BounceAudioEvent);
		
		if (Player.IsAnyCapabilityActive(UCharacterGroundPoundFallCapability::StaticClass()))
			bGroundPounded = true;
			
		Player.SetCapabilityAttributeValue(n"VerticalVelocity", VerticalVelocity);
		Player.SetCapabilityAttributeValue(n"HorizontalVelocityModifier", HorizontalVelocityModifier);
		Player.SetCapabilityActionState(n"Bouncing", EHazeActionState::Active);
		
		if (Player.IsAnyCapabilityActive(MovementSystemTags::GroundPound))
			SetAnimBoolParam(n"AnimParam_GroundPound", true);
		else
			SetAnimBoolParam(n"AnimParam_TopHit", true);

		BP_OnBounceReaction();
    }

	UFUNCTION(BlueprintEvent)
	void BP_OnBounceReaction()
	{

	}
}