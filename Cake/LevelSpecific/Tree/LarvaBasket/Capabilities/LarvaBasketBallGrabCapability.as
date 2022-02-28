import Cake.LevelSpecific.Tree.LarvaBasket.LarvaBasketPlayerComponent;
import Cake.LevelSpecific.Tree.LarvaBasket.LarvaBasketManager;

class ULarvaBasketGrabAnimNotify : UAnimNotify {}
class ULarvaBasketBallGrabCapability : UHazeCapability
{
	default BlockExclusionTags.Add(n"LarvaBasket");
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityDebugCategory = n"LarvaBasket";
	default TickGroup = ECapabilityTickGroups::BeforeMovement;
	default TickGroupOrder = 105;

	AHazePlayerCharacter Player;
	UHazeMovementComponent MoveComp;
	ULarvaBasketPlayerComponent BasketComp;
	ALarvaBasketManager LarvaBasketManager;  

	bool bBallIsGrabbed = true;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		BasketComp = ULarvaBasketPlayerComponent::Get(Owner);
		MoveComp = UHazeMovementComponent::Get(Owner);
		
		LarvaBasketManager = GetLarvaBasketManager();
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (BasketComp.CurrentCage == nullptr)
			return EHazeNetworkActivation::DontActivate;

		if (BasketComp.HeldBall != nullptr)
			return EHazeNetworkActivation::DontActivate;

		if (MoveComp.IsAirborne())
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (BasketComp.CurrentCage == nullptr)
			return EHazeNetworkDeactivation::DeactivateLocal;

		if (MoveComp.BecameAirborne())
			return EHazeNetworkDeactivation::DeactivateLocal;

		if (bBallIsGrabbed)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if (WasActionStarted(ActionNames::MovementJump))
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		//Sets these to false in case game ends midway through animation. Ensures reaction anims don't activate
		if (Player == Game::May)
			LarvaBasketManager.bCanPlayReaction[0] = false;
		else
			LarvaBasketManager.bCanPlayReaction[1] = false;

		bBallIsGrabbed = false;

		Player.BindOneShotAnimNotifyDelegate(
			ULarvaBasketGrabAnimNotify::StaticClass(),
			FHazeAnimNotifyDelegate(this, n"HandleGrabAnimNotify")
		);
	}

	UFUNCTION()
	void HandleGrabAnimNotify(AHazeActor Actor, UHazeSkeletalMeshComponentBase SkelMesh, UAnimNotify Notify)
	{
		bBallIsGrabbed = true;
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreDeactivation(FCapabilityDeactivationSyncParams& Params)
	{
		ALarvaBasketBall Ball = BasketComp.CurrentCage.GetAvailableBall();
		Params.AddObject(n"Ball", Ball);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams Params)
	{
		if (BasketComp.CurrentCage == nullptr)
			return;

		auto Ball = Cast<ALarvaBasketBall>(Params.GetObject(n"Ball"));
		// Make sure its deactivated, it might not be if its recycled, or remote side
		Ball.DeactivateBall();

		Ball.ActivateBall();
		Ball.AttachToComponent(Player.Mesh, n"RightAttach");
		Ball.ActorRelativeTransform = FTransform(FVector(0.f, 0.f, 22.f));

		BasketComp.HeldBall = Ball;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		//GrabTimer -= DeltaTime;
		MoveComp.SetSubAnimationTagToBeRequested(n"GrabBall");
	}

	//When animation finish, set can play reaction to true again
	UFUNCTION()
	void GrabAnimBlendOut()
	{
		if (LarvaBasketManager.State == ELarvaBasketGameState::Finish)
			LarvaBasketManager.PlayReactionAnimation(Player);

		if (Player == Game::May)
			LarvaBasketManager.bCanPlayReaction[0] = true;
		else
			LarvaBasketManager.bCanPlayReaction[1] = true;
	}
}