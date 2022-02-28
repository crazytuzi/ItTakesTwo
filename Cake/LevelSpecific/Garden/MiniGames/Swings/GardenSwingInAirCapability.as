import Cake.LevelSpecific.Garden.MiniGames.Swings.GardenSwingPlayerComponent;
import Vino.Movement.Components.MovementComponent;
import Vino.Movement.MovementSystemTags;

class UGardenSwingInAirCapability : UHazeCapability
{
	default CapabilityTags.Add(n"GardenSwings");

	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;

	AHazePlayerCharacter Player;
	UGardenSwingPlayerComponent SwingComp;
	AGardenSwingsActor Swings;

	//UGardenSingleSwingComponent PlayerSwing;

	UHazeMovementComponent MoveComp;
	UCharacterSlidingComponent SlideComp;

	bool bPlayedRumble = false;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		SwingComp = UGardenSwingPlayerComponent::Get(Owner);
		MoveComp = UHazeMovementComponent::Get(Owner);
		SlideComp = UCharacterSlidingComponent::Get(Owner);

		Swings = SwingComp.Swings;

		// if(Player.IsMay())
		// 	PlayerSwing = Swing.MaySwing;
		// else
		// 	PlayerSwing = Swing.CodySwing;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(SwingComp.bInAir)
			return EHazeNetworkActivation::ActivateFromControl;
		else
			return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(MoveComp.IsGrounded() && !SlideComp.bIsSliding)
			return EHazeNetworkDeactivation::DeactivateFromControl;
		else
			return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		SlideComp.bForcedSlideInput = false;

		Player.BlockCapabilities(CapabilityTags::Input, Swings);
		Player.BlockCapabilities(MovementSystemTags::Jump, Swings);

		Swings.PlayerSlideOverlap.OnComponentBeginOverlap.AddUFunction(this, n"OnComponentBeginOverlap");
		Swings.PlayerSlideOverlap.OnComponentEndOverlap.AddUFunction(this, n"OnComponentEndOverlap");

	}

	UFUNCTION()
	void OnComponentBeginOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
		UPrimitiveComponent OtherComponent, int OtherBodyIndex,
		bool bFromSweep, FHitResult& Hit)
	{
		AHazePlayerCharacter OverlappedPlayer = Cast<AHazePlayerCharacter>(OtherActor);

		if(OverlappedPlayer == Player)
			SlideComp.bForcedSlideInput = true;
	}

	UFUNCTION()
	void OnComponentEndOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor, UPrimitiveComponent OtherComponent, int OtherBodyIndex)
	{
		AHazePlayerCharacter OverlappedPlayer = Cast<AHazePlayerCharacter>(OtherActor);
		
		if(OverlappedPlayer == Player)
			SlideComp.bForcedSlideInput = false;		
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		
		if(Player.MovementComponent.BecameGrounded() && !bPlayedRumble)
		{
			if(SwingComp.bFailed)
				Player.PlayForceFeedback(Swings.ShortRumble, false, true, n"GardenSwingFailGrounded");
			else
				Player.PlayForceFeedback(Swings.GroundedRumble, false, true, n"GardenSwingGrounded");

			bPlayedRumble = true;
		}
	}


	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Swings.PlayerLanded(Player);
		
		SlideComp.bForcedSlideInput = false;
		SwingComp.bInAir = false;

		SwingComp.bAwaitingScore = true;

		if (Player == Game::May)
			Swings.bCompletedJump[0] = true;
		else
			Swings.bCompletedJump[1] = true;

		Swings.PlayerSlideOverlap.OnComponentBeginOverlap.UnbindObject(this);
		Swings.PlayerSlideOverlap.OnComponentEndOverlap.UnbindObject(this);

		if(Player.MovementComponent.BecameGrounded() && !bPlayedRumble)
		{
			if(SwingComp.bFailed)
				Player.PlayForceFeedback(Swings.ShortRumble, false, true, n"GardenSwingFailGrounded");
			else
				Player.PlayForceFeedback(Swings.ShortRumble, false, true, n"GardenSwingGrounded");
		}

		bPlayedRumble = false;

	}
}