import Cake.LevelSpecific.PlayRoom.GoldBerg.SlackLineBalanceBoard;
import Cake.LevelSpecific.PlayRoom.GoldBerg.SlackLineMonoWheel;

class SlacklineBalanceBoardCapability : UHazeCapability
{
	default TickGroup = ECapabilityTickGroups::ActionMovement;
	default TickGroupOrder = 100;

	AHazePlayerCharacter Player;
	ASlackLineBalanceBoard BalanceBoard;
	ASlackLineWheel MonoWheel;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		UObject AttributeBalanceBoard = GetAttributeObject(n"BalanceBoard");

		if (AttributeBalanceBoard != nullptr)
		{
			return EHazeNetworkActivation::ActivateLocal;
		}

		else
		{
        	return EHazeNetworkActivation::DontActivate;
		}
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		UObject AttributeBalanceBoard = GetAttributeObject(n"BalanceBoard");

		if (AttributeBalanceBoard != nullptr)
		{
			return EHazeNetworkDeactivation::DontDeactivate;
		}

		else
		{
        	return EHazeNetworkDeactivation::DeactivateLocal;
		}
	}


	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		
		Player.BlockCapabilities(n"Movement", this);
		MonoWheel = Cast<ASlackLineWheel>(GetAttributeObject(n"BalanceBoard"));

		Player.CleanupCurrentMovementTrail();
		
		Player.AttachToActor(Player.OtherPlayer, n"Totem", EAttachmentRule::SnapToTarget);

		BalanceBoard = MonoWheel.BalanceBoard;
		BalanceBoard.SetPlayerOwner(Player);
		System::SetTimer(this, n"AttachBalanceBoard", 0.4f, false);
	}

	UFUNCTION()
	void AttachBalanceBoard()
	{
		BalanceBoard.AttachToActor(Player, n"LeftAttach", EAttachmentRule::SnapToTarget);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Player.UnblockCapabilities(n"Movement", this);
		Player.ClearLocomotionAssetByInstigator(MonoWheel);
		Player.ClearCameraSettingsByInstigator(this);



		if (BalanceBoard != nullptr)
		{
			BalanceBoard.DetachFromActor(EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld);
			BalanceBoard.SetPlayerOwner(nullptr);
			BalanceBoard.Mesh.SetSimulatePhysics(true);
			BalanceBoard = nullptr;	
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		UpdateInput();
		SetLocomotionData();
	}

	void SetLocomotionData()
	{
		if (Player.Mesh.CanRequestLocomotion())
		{
			FHazeRequestLocomotionData Data;
			Data.AnimationTag = n"UniCycle";
			Player.RequestLocomotion(Data);
		}
	}

	void UpdateInput()
	{
		FVector MoveDirection = GetAttributeVector(AttributeVectorNames::MovementDirection);
		float MoveInput = MoveDirection.DotProduct(Player.ActorRightVector);
		BalanceBoard.SetBalanceInput(MoveInput);
	}
}