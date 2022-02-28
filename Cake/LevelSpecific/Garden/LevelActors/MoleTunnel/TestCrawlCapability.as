import Vino.Movement.MovementSettings;
import Vino.Movement.Components.MovementComponent;

UCLASS(Abstract)
class UTestCrawlCapability : UHazeCapability
{
	default CapabilityTags.Add(n"Example");

	default CapabilityDebugCategory = n"Example";
	
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;

	UPROPERTY()
	UAnimSequence MayCrawlAnim;

	UPROPERTY()
	UAnimSequence CodyCrawlAnim;

	AHazePlayerCharacter Player;
	UHazeMovementComponent MoveComp;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		MoveComp = UHazeMovementComponent::GetOrCreate(Player);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (WasActionStarted(ActionNames::MovementGroundPound) && MoveComp.IsGrounded())
        	return EHazeNetworkActivation::ActivateFromControl;
        
        return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (!IsActioning(ActionNames::MovementGroundPound) || !MoveComp.IsGrounded())
			return EHazeNetworkDeactivation::DeactivateFromControl;
		
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		UAnimSequence Anim = Player.IsCody() ? CodyCrawlAnim : MayCrawlAnim;
		Player.PlaySlotAnimation(Animation = Anim, bLoop = true);
		UMovementSettings::SetMoveSpeed(Player, 300.f, this, EHazeSettingsPriority::Defaults);
		float LocOffset = Player.IsCody() ? -55.f : -35.f;
		float RotOffset = Player.IsCody() ? 25.f : 20.f;
		Player.Mesh.SetRelativeLocation(FVector(0.f, 0.f, LocOffset));
		Player.Mesh.SetRelativeRotation(FRotator(RotOffset, 0.f, 0.f));
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Player.StopAnimation();
		UMovementSettings::SetMoveSpeed(Player, 800.f, this, EHazeSettingsPriority::Defaults);
		Player.Mesh.SetRelativeLocation(FVector::ZeroVector);
		Player.Mesh.SetRelativeRotation(FRotator::ZeroRotator);
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{

    }

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	

	}
}