import Vino.Interactions.Widgets.InteractionWidget;
import Cake.LevelSpecific.Tree.Boat.TreeBoatComponent;

class UTreeBoatSapThrottleWidgetCapability : UHazeCapability
{
	default CapabilityTags.Add(n"TreeBoat");
	default CapabilityTags.Add(n"TreeBoatThrottle");
	default CapabilityTags.Add(n"TreeBoatThrottleWidget");

	default TickGroup = ECapabilityTickGroups::GamePlay;

	default TickGroupOrder = 100;

	AHazePlayerCharacter Player;

	UTreeBoatComponent TreeBoatComponent;

	UInteractionWidget Widget;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		TreeBoatComponent = UTreeBoatComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
//		if(!System::IsValid(TreeBoatComponent.ActiveTreeBoat))
//			return EHazeNetworkActivation::DontActivate;

		if(TreeBoatComponent.ActiveTreeBoat == nullptr)
			return EHazeNetworkActivation::DontActivate;

		if(Player.IsAnyCapabilityActive(SapWeaponTags::Aim))
			return EHazeNetworkActivation::DontActivate;

		if(!Player.IsCody())
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
//		if(!System::IsValid(TreeBoatComponent.ActiveTreeBoat))
//			return EHazeNetworkDeactivation::DeactivateLocal;

		if(TreeBoatComponent.ActiveTreeBoat == nullptr)
			return EHazeNetworkDeactivation::DeactivateLocal;

		if(Player.IsAnyCapabilityActive(SapWeaponTags::Aim))
			return EHazeNetworkDeactivation::DeactivateLocal;

		if(!Player.IsCody())
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Widget = Cast<UInteractionWidget>(Player.AddWidget(TreeBoatComponent.SapThrottleWidgetClass));
		Widget.ActivationType = EHazeActivationType::PrimaryLevelAbility;
		Widget.AttachWidgetToComponent(TreeBoatComponent.ActiveTreeBoat.RotationPivot);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Player.RemoveWidget(Widget);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FVector Direction = Player.GetActorLocation() - TreeBoatComponent.ActiveTreeBoat.GetActorLocation();
		Direction = Direction.ConstrainToPlane(TreeBoatComponent.ActiveTreeBoat.RotationPivot.GetUpVector());
		Direction.Normalize();
		
		Direction = TreeBoatComponent.ActiveTreeBoat.RotationPivot.WorldTransform.InverseTransformVector(Direction);
		Widget.SetWidgetRelativeAttachOffset(Direction * TreeBoatComponent.ActiveTreeBoat.TreeBoatRadius);
//		Widget.SetWidgetWorldPosition(TreeBoatComponent.ActiveTreeBoat.RotationPivot.GetWorldLocation() + Direction * TreeBoatComponent.ActiveTreeBoat.TreeBoatRadius);

		Widget.bIsTriggerAvailable = TreeBoatComponent.bInWidgetRange;
		Widget.bIsTriggerFocused = TreeBoatComponent.bInSapThrottleRange;
	}

}