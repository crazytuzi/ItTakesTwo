import Vino.Interactions.InteractionComponent;

class ADrinkableBeer : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent Mesh;

	UPROPERTY(DefaultComponent)
	UInteractionComponent InteractionComponent;
	default InteractionComponent.ActionShape.BoxExtends = FVector(200.f, 200.f, 200.f);

	UPROPERTY(Category = "Drinkable Beer")
	TArray<UAnimSequence> MayAnimations;
	
	UPROPERTY(Category = "Drinkable Beer")
	TArray<UAnimSequence> CodyAnimations;

	AHazePlayerCharacter ActivatingPlayer;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		InteractionComponent.OnActivated.AddUFunction(this, n"HandleInteraction");
	}

	UFUNCTION()
	void HandleInteraction(UInteractionComponent InteractComp, AHazePlayerCharacter Player)
	{
		UAnimSequence DrinkAnimation;
		if (Player == Game::GetMay() && MayAnimations.Num() > 0)
			DrinkAnimation = MayAnimations[FMath::RandRange(0, MayAnimations.Num() - 1)];
		else if (Player == Game::GetCody() && CodyAnimations.Num() > 0)
			DrinkAnimation = CodyAnimations[FMath::RandRange(0, CodyAnimations.Num() - 1)];

		if (DrinkAnimation == nullptr)
			return;

		ActivatingPlayer = Player;
		ActivatingPlayer.PlaySlotAnimation(FHazeAnimationDelegate(), 
			FHazeAnimationDelegate(this, n"DrinkUnblock"), 
			DrinkAnimation);

		DrinkBlock();
	}

	UFUNCTION()
	void DrinkBlock()
	{
		InteractionComponent.Disable(n"InUse");
		ActivatingPlayer.BlockCapabilities(CapabilityTags::Movement, this);
		ActivatingPlayer.BlockCapabilities(CapabilityTags::Interaction, this);
	}
	
	UFUNCTION()
	void DrinkUnblock()
	{
		InteractionComponent.Enable(n"InUse");
		ActivatingPlayer.UnblockCapabilities(CapabilityTags::Movement, this);
		ActivatingPlayer.UnblockCapabilities(CapabilityTags::Interaction, this);
	}
}