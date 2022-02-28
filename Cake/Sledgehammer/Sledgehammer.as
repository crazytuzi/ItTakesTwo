import Vino.Movement.Components.MovementComponent;
import Vino.Characters.AICharacter;

settings SledgehammerMovementSettings for UMovementSettings
{
	SledgehammerMovementSettings.MoveSpeed = 600.f;
}

class ASledgehammer : AAICharacter
{
	default AIMovementComponent.DefaultMovementSettings = SledgehammerMovementSettings;
	
    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
		AIMovementComponent.Setup(CapsuleComponent);

        // Movement
		AddCapability(n"AICharacterFloorMoveCapability");
		AddCapability(n"AICharacterFloorJumpCapability");
		AddCapability(n"CharacterAirMoveCapability");
		AddCapability(n"CharacterFaceDirectionCapability");
		if(Network::IsNetworked() && Game::IsEditorBuild())
		{
			AddCapability(n"AISkeletalMeshNetworkVisualizationCapability");
		}
    }
};