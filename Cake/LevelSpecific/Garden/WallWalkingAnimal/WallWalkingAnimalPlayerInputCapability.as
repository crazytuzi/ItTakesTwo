import Cake.LevelSpecific.Garden.WallWalkingAnimal.WallWalkingAnimal;
import Cake.LevelSpecific.Garden.WallWalkingAnimal.WallWalkingAnimalComponent;
import Peanuts.Outlines.Outlines;
import Vino.Camera.Components.CameraUserComponent;
import Cake.LevelSpecific.Garden.Sickle.Player.Sickle;
import Cake.LevelSpecific.Garden.Vine.VineComponent;
import Cake.LevelSpecific.Garden.WaterHose.WaterHoseComponent;
import Cake.LevelSpecific.Garden.Sickle.SickleTags;

class UWallWalkingAnimalPlayerInputCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::LevelSpecific);
	default CapabilityTags.Add(CapabilityTags::Input);
	default CapabilityTags.Add(CapabilityTags::StickInput);
	default CapabilityTags.Add(CapabilityTags::MovementInput);
	default CapabilityTags.Add(AttributeVectorNames::MovementDirection);
	

	default CapabilityDebugCategory = n"LevelSpecific";
	
	default TickGroup = ECapabilityTickGroups::Input;
	default TickGroupOrder = 100;

	AHazePlayerCharacter Player;
	UWallWalkingAnimalComponent AnimalComp;
	UCameraUserComponent CameraUser;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		AnimalComp = UWallWalkingAnimalComponent::Get(Player);
		CameraUser = UCameraUserComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(AnimalComp.CurrentAnimal == nullptr)
        	return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(AnimalComp.CurrentAnimal == nullptr)
        	return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		SetMutuallyExclusive(AttributeVectorNames::MovementDirection, true);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		SetMutuallyExclusive(AttributeVectorNames::MovementDirection, false);
		if(AnimalComp.CurrentAnimal != nullptr)
			AnimalComp.CurrentAnimal.SpiderWantedMovementDirection = FVector::ZeroVector;
			
		FVector Temp;
		ConsumeAttribute(AttributeVectorNames::MovementDirection, Temp);
	}


	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		// Rotate the input in the spider space so forward is in the spiders forward
		const FRotator ControlRotation = Math::MakeRotFromYZ(Player.GetControlRotation().RightVector, AnimalComp.CurrentAnimal.GetMovementWorldUp());
		const FVector RawStick = GetAttributeVector(AttributeVectorNames::MovementRaw);
		FVector CurrentInput = ControlRotation.GetForwardVector() * RawStick.X + ControlRotation.GetRightVector() * RawStick.Y;
		
		// Update the input
		Player.SetCapabilityAttributeVector(AttributeVectorNames::MovementDirection, CurrentInput);
		AnimalComp.CurrentAnimal.SpiderWantedMovementDirection = CurrentInput;

		AnimalComp.CurrentAnimal.bHasAimDirection = CameraUser.IsAiming();
		AnimalComp.CurrentAnimal.PlayerDirection = Player.GetActorForwardVector();

		if(AnimalComp.CurrentAnimal.bHasAimDirection)
		{
			const FVector HorizontalViewDir = Player.GetControlRotation().ForwardVector.ConstrainToPlane(AnimalComp.CurrentAnimal.GetMovementWorldUp()).GetSafeNormal();
			if(HorizontalViewDir.IsNearlyZero())
				AnimalComp.CurrentAnimal.PlayerDirection = AnimalComp.CurrentAnimal.GetActorForwardVector();
			else
				AnimalComp.CurrentAnimal.PlayerDirection = HorizontalViewDir;
		}

		//if(TagIsBlocked(MovementSystemTags::TurnAround) || TagIsBlocked(CapabilityTags::CharacterFacing))
			

		// Debug
		//const FVector DebugLocation = Player.Mesh.GetSocketLocation(n"Head");
		//System::DrawDebugArrow(DebugLocation, DebugLocation + (CurrentInput * 300.f), Thickness = 4.f, ArrowSize = 25.f);
	}
}