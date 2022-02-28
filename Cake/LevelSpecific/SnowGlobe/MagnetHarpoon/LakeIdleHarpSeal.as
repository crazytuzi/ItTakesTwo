import Vino.BouncePad.BouncePadResponseComponent;
import Vino.Movement.Components.ImpactCallback.ActorImpactedCallbackGlobalBindFunctions;
import Vino.Movement.Capabilities.GroundPound.CharacterGroundPoundFallCapabilty;
import Cake.LevelSpecific.SnowGlobe.Swimming.SnowGlobeLakeDisableComponent;

class ALakeIdleHarpSeal : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UHazeSkeletalMeshComponentBase SkelMesh;

	UPROPERTY(DefaultComponent)
	UHazeDisableComponent HazeDisableComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	USnowGlobeLakeDisableComponentExtension HazeDisableCompExtension;

	UPROPERTY(DefaultComponent)
	UBouncePadResponseComponent BouncePadComp;

	UPROPERTY(Category = "Animation")
	UAnimSequence AnimSeqIdle;

	UPROPERTY(Category = "Animation")
	UAnimSequence AnimSeqBounce;

    UPROPERTY(Category = "Bounce Properties")
    float VerticalVelocity = 1000.f;

    UPROPERTY(Category = "Bounce Properties")
    float HorizontalVelocityModifier = 0.5f;

    UPROPERTY(Category = "Bounce Properties")
    float MaximumHorizontalVelocity = 500.f;

    UPROPERTY(EditDefaultsOnly, Category = "Bounce Properties")
    TSubclassOf<UHazeCapability> BouncePadCapabilityClass;
	default BouncePadCapabilityClass = Asset("/Game/Blueprints/LevelMechanics/YBP_CharacterBouncePad.YBP_CharacterBouncePad_C");
	
	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		FActorImpactedByPlayerDelegate OnPlayerLanded;
        OnPlayerLanded.BindUFunction(this, n"PlayerLandedOnBouncePad");
        BindOnDownImpactedByPlayer(this, OnPlayerLanded);

		FHazePlaySlotAnimationParams AnimParams;
		AnimParams.Animation = AnimSeqIdle;
		AnimParams.BlendTime = 0.1f;
		AnimParams.bLoop = true;
		AnimParams.StartTime = FMath::RandRange(0.f, 1.f);

		SkelMesh.PlaySlotAnimation(AnimParams);
	}

	UFUNCTION()
    void PlayerLandedOnBouncePad(AHazePlayerCharacter Player, FHitResult HitResult)
    {
        if (Player.HasControl())
			NetBounceReaction(Player);
    }

	UFUNCTION(NetFunction)
	void NetBounceReaction(AHazePlayerCharacter Player)
	{
		bool bGroundPounded = false;
		
		if (Player.IsAnyCapabilityActive(UCharacterGroundPoundFallCapability::StaticClass()))
			bGroundPounded = true;
			
		Player.SetCapabilityAttributeValue(n"VerticalVelocity", VerticalVelocity);
		Player.SetCapabilityAttributeValue(n"HorizontalVelocityModifier", HorizontalVelocityModifier);
		Player.SetCapabilityActionState(n"Bouncing", EHazeActionState::Active);

		FHazePlaySlotAnimationParams AnimParams;
		AnimParams.Animation = AnimSeqBounce;
		AnimParams.BlendTime = 0.2f;

		FHazeAnimationDelegate OnBlendingIn;
		FHazeAnimationDelegate OnBlendingOut;
		OnBlendingOut.BindUFunction(this, n"BounceAnimationFinished");
		
		SkelMesh.PlaySlotAnimation(OnBlendingIn, OnBlendingOut, AnimParams);
	}

	UFUNCTION()
	void BounceAnimationFinished()
	{
		FHazePlaySlotAnimationParams AnimParams;
		AnimParams.Animation = AnimSeqIdle;
		AnimParams.BlendTime = 0.1f;
		AnimParams.bLoop = true;

		SkelMesh.PlaySlotAnimation(AnimParams);
	}
}