# GitHub Action for labeling approved pull requests

This GitHub Action applies a label of your choice to pull requests that reach a specified number of approvals. For teams using [Pull Reminders](https://pullreminders.com), this action can be used to exclude approved pull requests from reminders.

## Usage

This Action subscribes to [Pull request review events](https://developer.github.com/v3/activity/events/types/#pullrequestreviewevent) which fire whenever pull requests are approved. The action requires two environment variables – a label name and the number of required approvals.

```workflow
workflow "Label approved pull requests" {
  on = "pull_request_review"
  resolves = ["Label when approved"]
}

action "Label when approved" {
  uses = "pullreminders/label-when-approved-action@master"
  secrets = ["GITHUB_TOKEN"]
  env = {
    LABEL_NAME = "approved"
    APPROVALS  = "2"
  }
}
```

## Demo

<img src="https://github.com/pullreminders/label-when-approved-action/raw/master/docs/images/demo.png" width="540">


## License

The Dockerfile and associated scripts and documentation in this project are released under the [MIT License](LICENSE).