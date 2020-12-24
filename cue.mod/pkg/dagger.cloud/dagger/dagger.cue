package dagger

// A DAG is the basic unit of programming in dagger.
// It is a special kind of program which runs as a pipeline of computing nodes running in parallel,
// instead of a sequence of operations to be run by a single node.
//
// It is a powerful way to automate various parts of an application delivery workflow:
// build, test, deploy, generate configuration, enforce policies, publish artifacts, etc.
//
// The DAG architecture has many benefits:
//  - Because DAGs are made of nodes executing in parallel, they are easy to scale.
//  - Because all inputs and outputs are snapshotted and content-addressed, DAGs
//		can easily be made repeatable, can be cached aggressively, and can be replayed
//		at will.
//  - Because nodes are executed by the same container engine as docker-build, DAGs
//		can be developed using any language or technology capable of running in a docker.
//		Dockerfiles and docker images are natively supported for maximum compatibility.
//
//  - Because DAGs are programmed declaratively with a powerful configuration language,
//		they are much easier to test, debug and refactor than traditional programming languages.
//
// To execute a DAG, the dagger runtime JIT-compiles it to a low-level format called
// llb, and executes it with buildkit.
// Think of buildkit as a specialized VM for running compute graphs; and dagger as
// a complete programming environment for that VM.
//
// The tradeoff for all those wonderful features is that a DAG architecture cannot be used
// for all software: only software than can be run as a pipeline.
//

// A dagger component is a configuration value augmented
// by scripts defining how to compute it, present it to a user,
// encrypt it, etc.

// FIXME: #Component will not match embedded scalars.
//   use Runtime.isComponent() for a reliable check
#Component: {
	#dagger: #ComponentConfig
	...
}

// The contents of a #dagger annotation
#ComponentConfig: {
	input?: bool

	// script to compute the value
	compute?:  #Script

	terminal?: {
		// Display a message when opening a terminal session
		greeting?: string
		command: [string]: #Script
	}
	// Configure how the component is incorporated to user settings.
	// Configure how the end-user can configure this component
	settings?: {
		// If not specified, scrape from comments
		title?:       string
		description?: string
		// Disable user input, even if incomplete?
		hidden: true | *false
		ui:     _ // insert here something which can be compiled to react-jsonschema-form
		// Show the cue default value to the user, as a default input value?
		showDefault: true | *false

		// Insert information needed by:
		//   1) clients to encrypt
		//  ie. web wizard, cli
		//   2) middleware to implement deicphering in the cuellb pipeline
		//  eg. integration with clcoud KMS, Vault...
		//
		//   3) connectors to make sure secrets are preserved 
		encrypt?: {
			pubkey: string
			cipher: string
		}
	}
}



// Any component can be referenced as a directory, since
// every dagger script outputs a filesystem state (aka a directory)
#Dir: #Component

#Script: [...#Op]

// One operation in a script
#Op: #FetchContainer | #FetchGit | #Export | #Exec | #Load | #Copy

// Export a value from fs state to cue
#Export: {
	do: "export"
	// Source path in the container
	source: string
	format: "json"|"yaml"|*"string"|"number"|"boolean"
}

#Load: #LoadComponent| #LoadScript | #LoadInput
#LoadComponent: {
	do: "load"
	from: #Component
}
#LoadScript: {
	do: "load"
	from: #Script
}
// Load an external input
#LoadInput: {
	do: "load"
	from: "input"
}


#Exec: {
	do: "exec"
	args: [...string]
	env: [string]: string
	always: true | *false
	dir: string | *"/"
	mount?: [string]: #MountTmp | #MountCache | #MountComponent | #MountScript
}

#MountTmp: "tmpfs"
#MountCache: "cache"
#MountComponent: {
	from: #Component
	path: string | *"/"
}
#MountScript: {
	from: #Script
	path: string | *"/"
}

#FetchContainer: {
	do: "fetch-container"
	ref: string
}

#FetchGit: {
	do: "fetch-git"
	remote: string
	ref: string
}

#Copy: {
	do: "copy"
	from: #Script | #Component
	src: string | *"/"
	dest: string | *"/"
}


#TestScript: #Script & [
	{ do: "fetch-container", ref: "alpine:latest" },
	{ do: "exec", args: ["echo", "hello", "world" ] }
]
